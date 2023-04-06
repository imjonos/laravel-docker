## Laravel Docker LAMP PHP 8.1 
./source dir for the laravel project 

## How to use

- copy .env.example to .env
- docker-compose build
- docker-compose up
- enjoy!

<b>Default http port:</b><br>
APACHE2_HTTP_PORT=8081<br>
App will be available here http://localhost:8081<br>
<br>
<b>Default MariaDB port:</b> <br>
MYSQL_PORT=3307 <br>
MYSQL_VOLUME=./database
<br><br>
LOGIN: docker<br> 
PASSWORD: docker<br>
DB: docker<br> 
<br>
<b>Default SSH port:</b> <br>
SSH_PORT=2222<br>
<br>
LOGIN: docker<br> 
PASSWORD: docker<br>
<br>
<b>Default phpmyadmin port:</b><br>
PHPMYADMIN_PORT=8080<br>
Phpmyadmin will be availible here http://localhost:8080<br>
<br>
<b>Default redis port:</b><br>
REDIS_PORT=6380<br>
