# Simple Api

## docker
docker build -t users-api .
docker run -p 3000:3000 users-api

## curl
curl localhost:3000/users
curl localhost:3000/users --josn '{"name": "James"}'
