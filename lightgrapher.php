<?php
header('Content-disposition: attachment; filename=lightgrapher.swf');
header('Content-type: application/x-shockwave-flash');
readfile('lightgrapher.swf');
?>