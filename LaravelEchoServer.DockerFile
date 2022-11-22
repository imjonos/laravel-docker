FROM oanhnn/laravel-echo-server:latest
ENV LARAVEL_ECHO_SERVER_DEBUG='true'
COPY ./config/laravel-echo-server.json /app/laravel-echo-server.json
EXPOSE 6001
#WORKDIR /var/www/localhost

#CMD ["laravel-echo-server", "start"]

