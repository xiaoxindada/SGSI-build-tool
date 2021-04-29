#!/usr/bin/env python

import argparse
import errno
import os

import update_payload
from update_payload import applier


def list_content(payload_file_name):
    with open(payload_file_name, 'rb') as payload_file:
        payload = update_payload.Payload(payload_file)
        payload.Init()

        for part in payload.manifest.partitions:
            print("{} ({} bytes)".format(part.partition_name,
                                         part.new_partition_info.size))


def extract(payload_file_name, output, partition_names=None):
    if not os.path.isdir(output):
        os.makedirs(output)

    with open(payload_file_name, 'rb') as payload_file:
        payload = update_payload.Payload(payload_file)
        payload.Init()

        if payload.IsDelta():
            print("Delta payloads are not supported")
            exit(1)

        helper = applier.PayloadApplier(payload)
        for part in payload.manifest.partitions:
            if partition_names and part.partition_name not in partition_names:
                continue
            print("Extracting {}".format(part.partition_name + '.img...'))
            output_file = os.path.join(output, part.partition_name + '.img')
            helper._ApplyToPartition(
                part.operations, part.partition_name,
                'install_operations', output_file,
                part.new_partition_info)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("payload", metavar="payload.bin",
                        help="Path to the payload.bin")
    parser.add_argument("output", default="out",
                        help="Output directory")
    parser.add_argument("--partitions", type=str, nargs='+',
                        help="Name of the partitions to extract")
    parser.add_argument("--list_partitions", action="store_true",
                        help="List the partitions included in the payload.bin")

    args = parser.parse_args()
    if args.list_partitions:
        list_content(args.payload)
    else:
        extract(args.payload, args.output, args.partitions)
