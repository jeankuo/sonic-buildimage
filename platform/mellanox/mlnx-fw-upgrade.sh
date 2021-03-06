#!/bin/bash

query_retry_count_max="10"
fw_file=/etc/mlnx/fw-SPC.mfa

run_or_fail() {
	$1
	if [[ $? != 0 ]]; then
		echo $1 failed
		exit 1
	fi
}

# wait until devices will be available
query_retry_count="0"
query_cmd="mlxfwmanager --query -i ${fw_file}"
${query_cmd} > /dev/null

while [[ (${query_retry_count} -lt ${query_retry_count_max}) && ($? -ne "0") ]]; do
	sleep 1
	query_retry_count=$[${query_retry_count}+1]
	${query_cmd} > /dev/null
done

run_or_fail "${query_cmd}" > /tmp/mlnxfwmanager-query.txt

# get current firmware version and required version
fw_info=$(grep FW /tmp/mlnxfwmanager-query.txt)
fw_current=$(echo $fw_info | cut -f2 -d' ')
fw_required=$(echo $fw_info | cut -f3 -d' ')

if [[ -z ${fw_current} ]]; then
	echo "Could not retreive current FW version."
	exit 1
fi

if [[ -z ${fw_required} ]]; then
	echo "Could not retreive required FW version."
	exit 1
fi

if [[ ${fw_current} == ${fw_required} ]]; then
	echo "Mellanox firmware is up to date."
else
	echo "Mellanox firmware required version is ${fw_required}. Installing compatible version..."
	run_or_fail "mlxfwmanager -i ${fw_file} -u -f -y"
fi
