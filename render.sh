#!/bin/bash

for TAG in full light extras
do
    rm -fr $TAG
    mkdir $TAG
    sed "s/%tag%/$TAG/g" template > $TAG/Dockerfile
    cp yeast $TAG/
done
