#!/bin/bash

if ! [ -f /tmp/desk01 ]; then
  touch /tmp/desk01
  sudo steamos-desktop-select
fi
