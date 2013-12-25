#!/bin/bash
# Run a capistrano task corresponds to a serf event
#
# Setup:
#   $ bundle install --path vendor/bundle
#   $ bundle exec cap install
#
# Usage: 
# agent1:
#   ./serf agent -role=monitor -node=agent-one -bind=127.0.0.1:7946 -log-level=debug -event-handler="./preserve_path $PATH ./serf-capistrano3.sh test 127.0.0.1:7373" -rpc-addr=127.0.0.1:7373
#   ./serf agent -role=deployer -node=agent-two -bind=127.0.0.1:7947 -log-level=debug -event-handler="./preserve_path $PATH ./serf-capistrano3.sh test 127.0.0.1:7371" -rpc-addr=127.0.0.1:7371
#   ./serf agent -role=load-balancer -node=agent-three -bind=127.0.0.1:7948 -log-level=debug -event-handler="./preserve_path $PATH ./serf-capistrano3.sh test 127.0.0.1:7372" -rpc-addr=127.0.0.1:7372
#   ./serf agent -role=web -node=agent-four -bind=127.0.0.1:7949 -log-level=debug -event-handler="./preserve_path $PATH ./serf-capistrano3.sh test 127.0.0.1:7374" -rpc-addr=127.0.0.1:7374
#   ./serf join --rpc-addr=127.0.0.1:7371 127.0.0.1:7946
#   ./serf join --rpc-addr=127.0.0.1:7372 127.0.0.1:7946
#   ./serf join --rpc-addr=127.0.0.1:7374 127.0.0.1:7946
#
# Also, you can manually test reactions on user events as follows:
#   serf event -rpc-addr=127.0.0.1:7371 web-deployed 'agent-four 127.0.0.1 web'
#
# Test:
#   $ env SERF_EVENT=member-join SERF_SELF_NAME=self-name SERF_SELF_ROLE=self-role sh -c 'echo the_name the_address the_role | ./serf-capistrano3.sh'
#   My role is self-role
#   Running cap bundle exec cap self serf:on-member-join[the_name,the_address,the_role] in /home/vagrant/serf-capistrano3
#   {:name=>"the_name", :address=>"the_address", :role=>"the_role"}
#   ...
#    My role is self-role
#    Running cap bundle exec cap self serf:on-the_role-member-join[the_name,the_address,the_role] in /home/vagrant/serf-capistrano3
#    {:name=>"the_name", :address=>"the_address", :role=>"the_role"}
#
# Ex: "serf event boot"
PAYLOAD=$(cat)
USER_EVENT_DATA_CSV_1=$(echo $PAYLOAD | cut -f1 -d,)
USER_EVENT_DATA_CSV_2=$(echo $PAYLOAD | cut -f2 -d,)
PAYLOAD_ARGS=$(echo $PAYLOAD | awk '{sum=$1; for (i=2; i<=NF; i++) {sum = sum "," $i }; print sum }')
MEMBERSHIP_EVENT_DATA_1=$(echo $PAYLOAD | awk '{print $1}')
MEMBERSHIP_EVENT_DATA_2=$(echo $PAYLOAD | awk '{print $2}')
MEMBERSHIP_EVENT_DATA_3=$(echo $PAYLOAD | awk '{print $3}')
NAME=$MEMBERSHIP_EVENT_DATA_1
ADDRESS=$MEMBERSHIP_EVENT_DATA_2
ROLE=$MEMBERSHIP_EVENT_DATA_3
BUILD_DIR=`mktemp -d`
DIR=$(dirname $0)
SERF_RPC_ADDR=$2

echo Payload: $PAYLOAD
echo Directory: $DIR

cd $DIR

CWD=$(pwd)
BUNDLE_PATH="/opt/chef/embedded/bin/bundle"
CAP_CMD="$BUNDLE_PATH exec cap"
STAGE=test
if [ "$1" != "" ]; then
  STAGE="$1"
fi

# SERF_EVENT will be one of: member-join, member-leave, member-failed, user

CAP_STAGE=${STAGE}
CAP_TASK1=serf:on-${SERF_EVENT}
CAP_TASK2=serf:on-${ROLE}-${SERF_EVENT}

if [ "$SERF_EVENT" == "user" ]; then
  CMD1="$CAP_CMD $CAP_STAGE $CAP_TASK1[$SERF_USER_EVENT,$PAYLOAD_ARGS]"
else
  CMD1="$CAP_CMD $CAP_STAGE $CAP_TASK1[$NAME,$ADDRESS,$ROLE]"
fi

echo "My role is $SERF_SELF_ROLE"

echo "Running cap $CMD1 in $CWD"
env MY_ROLE=$SERF_SELF_ROLE SERF_RPC_ADDR=$SERF_RPC_ADDR $CMD1

rm -rf $BUILD_DIR
