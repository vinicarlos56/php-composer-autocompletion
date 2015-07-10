<?php

$autoload = $argv[1];

$name = $argv[2];

require $autoload;

$reflected = new ReflectionClass($name);

function visibility($type)
{
    if ($type->isPrivate()) {
        return 'private';
    } else if($type->isPublic()) {
        return 'public';
    } else if($type->isProtected()) {
        return 'protected';
    }
}

function createSnippet($method)
{
    if (empty($method->getParameters())) {
        return $method->name.'()${2}';
    }

    $out = '';
    foreach ($method->getParameters() as $idx => $param) {
        $out .= '${'.($idx+2).':$'.$param->name.'},';
    }

    return $method->name.'('.substr($out,0,-1).')${'.($idx+3).'}';
}

function createDisplayText($method)
{
    if (empty($method->getParameters())) {
        return $method->name.'()';
    }

    $out = [];
    foreach ($method->getParameters() as $idx => $param) {
        $className = $param->getClass() ? $param->getClass().' ' : ''; 
        $out[] = $className.'$'.$param->name;
    }

    return $method->name.'('.implode($out,', ').')';
}

$methods = $properties = $constants = [];

foreach ($reflected->getMethods() as $method) {
    $methods[] = [
        'name' => createDisplayText($method),
        'visibility' => visibility($method),
        'snippet' => createSnippet($method),
        'isStatic' => $method->isStatic(),
        'type' => 'method' 
    ];
}

foreach ($reflected->getProperties() as $property) {
    $properties[] = [
        'name' => $property->name,
        'visibility' => visibility($property),
        'snippet' => $property->name.'${2}',
        'isStatic' => $property->isStatic(),
        'type' => 'property' 
    ];
}

foreach ($reflected->getConstants() as $name => $value) {
    $constants[] = [
        'name' => $name,
        'type' => 'constant',
        'snippet' => $name.'${2}',
    ];
}

echo json_encode($properties+$constants+$methods);
echo PHP_EOL;
