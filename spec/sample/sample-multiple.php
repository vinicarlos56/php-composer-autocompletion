<?php

class TestClass
{

    function __construct($test)
    {
        $this->test = $test;
    }

    public function firstMethod($firstParam,$secondParam)
    {

    }

    public function secondParam(KnownObject $firstParam, Second $second)
    {
        // code...
    }

    public function thirdMethod(KnownObject $first,
                                Second $second,
                                Third $third)
    {
        // code...
    }

}

