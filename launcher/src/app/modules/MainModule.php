<?php
namespace app\modules;

use facade\Json;
use std, gui, framework, app;
use php\net\UDPSocket;
use php\net\UDPSocketPacket;

Class Encoder
{
  private function lshift($w, $a)
  { return $w << $a; }
  private function rshift($w, $a)
  { return $w >> $a; }
  function encodeUInt8($data)
  {
    $data = gettype($data) == 'integer' ? $data : 0;
    return chr($data & 0xFF);
  }
  function decodeUInt8($data)
  {
    if (gettype($data) != 'string') 
      return 0;
    return ord($data);
  }
  function encodeUInt16($data)
  {
    $data = gettype($data) == 'integer' ? $data : 0;
    return chr(($this->rshift($data, 8) & 0xFF)) 
          .chr(($this->rshift($data, 0) & 0xFF));
  }
  function decodeUInt16($data)
  {
    if (gettype($data) != 'string') 
      return 0;
    $chrs = str_split($data, 1);
    $b1 = ord($data[0]);
    $b2 = ord($data[1]);
    return $this->lshift($b1, 8) | $b2;
  }
  function encodeUInt32($data)
  {
    $data = gettype($data) == 'integer' ? $data : 0;
    return chr(($this->rshift($data, 24) & 0xFF)) 
          .chr(($this->rshift($data, 16) & 0xFF)) 
          .chr(($this->rshift($data, 8) & 0xFF)) 
          .chr(($this->rshift($data, 0) & 0xFF));
  }
  function decodeUInt32($data)
  {
    if (gettype($data) != 'string') 
      return 0;
    $chrs = str_split($data, 1);
    $b1 = ord($data[0]);
    $b2 = ord($data[1]);
    $b3 = ord($data[2]);
    $b4 = ord($data[3]);
    return $this->lshift($b1, 24) 
          | $this->lshift($b2, 16)  
          | $this->lshift($b3, 8) | $b4;
  }
}

class MainModule extends AbstractModule
{

    /**
     * @event construct 
     */
    function doConstruct(ScriptEvent $e = null)
    {    
        global $servers, $client, $encoder, $launcher;
        $servers = Json::fromFile('slmp_servers.json');
        $launcher = Json::fromFile('slmp_settings.json');
        if ($servers == null)
            $servers = [];
        if ($launcher == null)
            $launcher = ['name' => ''];
        $this->edit->text = $launcher['name'];
        $this->loadMyServers();
        $client = new UDPSocket;
        $encoder = new Encoder;
    }
    function loadMyServers()
    {
        global $servers;
        $this->form('MainForm')->tabPane->selectedIndex = 0;
        $this->form('MainForm')->table->items->clear();
        foreach($servers as $k => $v)
            $this->form('MainForm')->table->items->add($v);
    } 
    function pingServer($ip, $port)
    {
        global $client, $encoder;
        $command = 'SLMPQUERY';
        $packet = new UDPSocketPacket(strlen($command), $ip, $port);
        $packet->setData($command);
        $client->send($packet);
        $time = microtime();
        $thread = new Thread(function(){
            global $client, $packet;
            $packet = new UDPSocketPacket(1024);
            $client->receive($packet);
            uiLater(function(){
                global $packet, $encoder, $time, $servers;
                
                $str = $packet->getData();
                $chr = substr($str, 0, 4);
                if ($chr == 'SLMP')
                {
                    $arr = Regex::split('[//|]+', $str);
                    $this->textArea->text .= PHP_EOL . 'SLMP!';
                    $was = $this->table->selectedItem;
                    //$this->form('MainForm')->table->items->removeByIndex($this->form('MainForm')->table->selectedIndex);
                    $was['players'] = strval($arr[1]) . ' / ' . strval($arr[2]);
                    $was['ping'] = strval(microtime() - $time);
                    $was['hostname'] = strval($arr[3]);
                    $was['language'] = strval($arr[5]);
                    $sel = $this->table->selectedIndex;
                    $this->table->items->set($this->table->selectedIndex, $was);
                    $this->table->selectedIndex = $sel;
                    
                    $this->table3->items->clear();
                    $this->table3->items->add(['name' => 'version', 'value' => $arr[4]]);
                    $this->table3->items->add(['name' => 'language', 'value' => $arr[5]]);
                    $this->table3->items->add(['name' => 'ping', 'value' => strval(microtime() - $time) . ' ms']);
                    $this->table3->items->add(['name' => 'maxplayers', 'value' => strval($arr[2])]);
                    
                    $this->tableAlt->items->clear();
                    
                    $players = 7;
                    while ($players >= 7)
                    {
                        if (!isset($arr[$players]) || !isset($arr[$players+1]) || !isset($arr[$players+2])) break;
                        $playerid = strval($arr[$players]); $players++;
                        $name = strval($arr[$players]); $players++;
                        $ping = strval($arr[$players]); $players++;
                        $this->tableAlt->items->add(['id' => $playerid, 'nickname' => $name, 'ping' => $ping]);
                    }
                    
                    foreach ($servers as $k => $v)
                        if ($v['address'] == $was['address'])
                            $servers[$k]['hostname'] = strval($arr[3]);
                }
                
                $this->textArea->text .= PHP_EOL . "Receive packet from: {$packet->getSocketAddress()}";
                $this->textArea->text .= PHP_EOL . "Packet data: {$packet->getData()}\n";
            });
        });
        $thread->start();
    }
}
