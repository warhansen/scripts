To use this docker, first create the docker using the dockerfile inside the "docker" directory.

Once that is complete, then run with this command:

docker run -d -p port:5000 -v app_directory:/home flask_image

where:

"port" = The port you want to listen on

"app_directory" = The directory where you single application file is located

"flask_image" = The image name of your flask image you created in step 1