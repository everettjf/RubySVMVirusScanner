#!/bin/sh
ruby rvsscan.rb --train /Users/everettjf/Virus/train/train_health /Users/everettjf/Virus/train/train_virus
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/train_virus
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/train_health
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/test_virus
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/test_health

