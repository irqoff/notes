<?php
if (rand(0,3) == 0) {
        header("HTTP/1.0 404 Not Found");
}
sleep(rand(0,4)+time()%4);
