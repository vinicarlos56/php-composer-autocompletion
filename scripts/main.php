<?php

$autoload = $argv[1];

$name = $argv[2];

require $autoload;

$reflected = new ReflectionClass($name);

$methods = [];
foreach ($reflected->getMethods() as $method) {
    $methods[] = $method->name;
}

echo json_encode($methods);
echo PHP_EOL;
