#!/bin/bash
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

TYPE=$1
shift
curl -X GET -s --data-urlencode "q=$@" http://localhost:$((13000 + $UID))/$TYPE
