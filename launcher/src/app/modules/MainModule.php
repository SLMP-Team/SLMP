<?php
namespace app\modules;

use facade\Json;
use std, gui, framework, app;
use php\net\UDPSocket;
use php\net\UDPSocketPacket;


class MainModule extends AbstractModule
{

    /**
     * @event construct 
     */
    function doConstruct(ScriptEvent $e = null)
    {    
        global $servers, $client;
        $servers = Json::fromFile('slmp-settings.json');
        if ($servers == null)
            $servers = [];
        $this->loadMyServers();
        $client = new UDPSocket;
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
        global $client;
        $command = 'SLMP|PING';
        $packet = new UDPSocketPacket(strlen($command), $ip, $port);
        $packet->setData($command);
        $client->send($packet);
    }
}
