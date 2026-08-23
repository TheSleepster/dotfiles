#!/bin/bash

directory_name="$1"

mkdir -p ${directory_name} \
    ${directory_name}/code \
    ${directory_name}/build \
    ${directory_name}/misc \
    ${directory_name}/run_tree \
    ${directory_name}/run_tree/res \
    ${directory_name}/run_tree/res/textures/ \
    ${directory_name}/run_tree/res/sounds/ \
    ${directory_name}/run_tree/res/fonts/ \
    ${directory_name}/run_tree/res/shaders/ \
    ${directory_name}/run_tree/res/models/ \
    ${directory_name}/run_tree/deps \
