<?php

$autoload = $argv[1];

$name = $argv[2];

require $autoload;

try{

    $reflected = new ReflectionClass($name);

} catch(Exception $e) {
    echo json_encode(['error' => 'class not found']).PHP_EOL;
    exit();
}

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

    $out = array();
    foreach ($method->getParameters() as $idx => $param) {
        $className = $param->getClass() ? $param->getClass()->getShortName().' ' : '';
        $out[] = $className.'$'.$param->name;
    }

    return $method->name.'('.implode($out,', ').')';
}

$methods = $properties = $constants = array();

foreach ($reflected->getMethods() as $method) {
    $methods[] = array( 
        'name' => createDisplayText($method),
        'visibility' => visibility($method),
        'snippet' => createSnippet($method),
        'isStatic' => $method->isStatic(),
        'type' => 'method'
    );
}

foreach ($reflected->getProperties() as $property) {
    $properties[] = array( 
        'name' => $property->name,
        'visibility' => visibility($property),
        'snippet' => $property->name.'${2}',
        'isStatic' => $property->isStatic(),
        'type' => 'property'
    );
}

foreach ($reflected->getConstants() as $name => $value) {
    $constants[] = array(
        'name' => $name,
        'type' => 'constant',
        'snippet' => $name.'${2}',
    );
}

echo json_encode(array_merge($properties,$constants,$methods));
echo PHP_EOL;
