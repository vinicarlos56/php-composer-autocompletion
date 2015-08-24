<?php namespace Full\Name\Space;

use Closure;

class SomeParent
{
    public $publicVar;

    function __construct($test)
    {
        $this->test = $test;
    }

    public function firstMethod($firstParam,$secondParam)
    {
        // code...
    }

    private function parMethod()
    {
        // code...
    }

    protected function last(Closure $callback)
    {
        // code...
    }
}

