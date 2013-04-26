<?php
//$name = $_POST['name'];
//$file = base64_decode($_POST['image']);
//$f = fopen("C:\\Users\\Ben\\Dropbox\\HelloWorld\\bin\\".$name.".png", "w");
//$log = fopen("C:\\Users\\Ben\\Dropbox\\HelloWorld\\bin\\log.txt", "w");
$f = fopen("public\\temp.png");
fwrite($f, $GLOBALS['HTTP_RAW_POST_DATA']);
fclose($f);

$log = fopen("log.txt", "w");
//fwrite($f, $file);
fwrite($log, "Image writted");
//fclose($f);
fclose($log);

?>