#!/bin/bash


# build checkoutservice
docker build -t checkoutservice -f src/checkoutservice/Dockerfile src/checkoutservice
CHECKOUTSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^checkoutservice " | cut -d' ' -f2)
docker tag $CHECKOUTSERVICE_IMAGE_ID meghnapancholi/online-boutique:checkoutservice-sleep
docker push meghnapancholi/online-boutique:checkoutservice-sleep

# build cartservice
docker build -t cartservice -f src/cartservice/src/Dockerfile src/cartservice/src
CARTSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^cartservice " | cut -d' ' -f2)
docker tag $CARTSERVICE_IMAGE_ID meghnapancholi/online-boutique:cartservice-sleep
docker push meghnapancholi/online-boutique:cartservice-sleep

# build currencyservice
docker build -t currencyservice -f src/currencyservice/Dockerfile src/currencyservice
CURRENCYSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^currencyservice " | cut -d' ' -f2)
docker tag $CURRENCYSERVICE_IMAGE_ID meghnapancholi/online-boutique:currencyservice-sleep
docker push meghnapancholi/online-boutique:currencyservice-sleep

