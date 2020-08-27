#!/usr/bin/php
<?php
require "HZ2PY.php";
$fileList = [
	"/home/davidwei/Projects/background_shop/Yangtaoabc.Api/Data/shoppingcart/en.json",
	"/home/davidwei/Projects/background_shop/Yangtaoabc.Api/Data/mainbody/en.json",
	"/home/davidwei/Projects/background_shop/Yangtaoabc.Api/Data/header/en.json",
];
foreach($fileList as $file)
	file_put_contents($file, HZ2PY::getPinyin(file_get_contents($file), true, false));

