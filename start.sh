#!/bin/bash

gnome-terminal -t "login" -- bash -c "./skynet/skynet configs/config_login"
gnome-terminal -t "db" -- bash -c "./skynet/skynet configs/config_mongodb"
