#!/bin/bash
eachDir(){
    for file in $1/*
    do
        if test -f $file;then
            if [ ${file##*.} = 'proto' ];then
                filepath=${file%/*}"/"$(basename $file .proto)".pb"
                ./tools/protoc --descriptor_set_out=$filepath $file
                echo $file" -> "$filepath
            fi
        fi
        if test -d $file
        then
            eachDir $file
        fi
    done
}
eachDir ./src/proto
