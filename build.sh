#!/bin/bash


# # build checkoutservice
# docker build -t checkoutservice -f src/checkoutservice/Dockerfile src/checkoutservice
# CHECKOUTSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^checkoutservice " | cut -d' ' -f2)
# docker tag $CHECKOUTSERVICE_IMAGE_ID meghnapancholi/online-boutique:checkoutservice-sleep
# docker push meghnapancholi/online-boutique:checkoutservice-sleep

# # build cartservice
# docker build -t cartservice -f src/cartservice/src/Dockerfile src/cartservice/src
# CARTSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^cartservice " | cut -d' ' -f2)
# docker tag $CARTSERVICE_IMAGE_ID meghnapancholi/online-boutique:cartservice-sleep
# docker push meghnapancholi/online-boutique:cartservice-sleep

# # build currencyservice
# docker build -t currencyservice -f src/currencyservice/Dockerfile src/currencyservice
# CURRENCYSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^currencyservice " | cut -d' ' -f2)
# docker tag $CURRENCYSERVICE_IMAGE_ID meghnapancholi/online-boutique:currencyservice-sleep
# docker push meghnapancholi/online-boutique:currencyservice-sleep

# # build frontend
# docker build -t frontend -f src/frontend/Dockerfile src/frontend
# FRONTEND_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^frontend " | cut -d' ' -f2)
# docker tag $FRONTEND_IMAGE_ID meghnapancholi/online-boutique:frontend-sleep
# docker push meghnapancholi/online-boutique:frontend-sleep

# # build adservice
# docker build -t adservice -f src/adservice/Dockerfile src/adservice
# ADSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^adservice " | cut -d' ' -f2)
# docker tag $ADSERVICE_IMAGE_ID meghnapancholi/online-boutique:adservice-sleep
# docker push meghnapancholi/online-boutique:adservice-sleep

# # build shippingservice
# docker build -t shippingservice -f src/shippingservice/Dockerfile src/shippingservice
# SHIPPINGSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^shippingservice " | cut -d' ' -f2)
# docker tag $SHIPPINGSERVICE_IMAGE_ID meghnapancholi/online-boutique:shippingservice-sleep
# docker push meghnapancholi/online-boutique:shippingservice-sleep

# #build emailservice
# docker build -t emailservice -f src/emailservice/Dockerfile src/emailservice
# EMAILSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^emailservice " | cut -d' ' -f2)
# docker tag $EMAILSERVICE_IMAGE_ID meghnapancholi/online-boutique:emailservice-sleep
# docker push meghnapancholi/online-boutique:emailservice-sleep

# build productcatalogservice
docker build -t productcatalogservice -f src/productcatalogservice/Dockerfile src/productcatalogservice
PRODUCTCATALOGSERVICE_IMAGE_ID=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^productcatalogservice " | cut -d' ' -f2)
docker tag $PRODUCTCATALOGSERVICE_IMAGE_ID meghnapancholi/online-boutique:productcatalogservice-sleep
docker push meghnapancholi/online-boutique:productcatalogservice-sleep



