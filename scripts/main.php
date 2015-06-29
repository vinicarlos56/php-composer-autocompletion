<?php

$autoload = $argv[1];

$name = $argv[2];

require $autoload;

$reflected = new ReflectionClass($name);

function visibility($method)
{
    if ($method->isPrivate()) {
        return 'private';
    } else if($method->isPublic()) {
        return 'public';
    } else if($method->isProtected()) {
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

$methods = [];
foreach ($reflected->getMethods() as $method) {
    $methods[] = [
        'name' => $method->name,
        'visibility' => visibility($method),
        'snippet' => createSnippet($method),
        'isStatic' => $method->isStatic()
    ];
}

echo json_encode($methods);
echo PHP_EOL;
