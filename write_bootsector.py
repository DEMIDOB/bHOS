import sys
import logging


def main(argc, argv):
    if argc < 3:
        logging.error("Not enough arguments")
        exit()

    source_filename = argv[1]
    target_filename = argv[2]

    logging.info(f"Writing bootsector from {source_filename} to {target_filename}")

    with open(source_filename, "rb") as source_file:
        bootsector_data = source_file.read(1024)

    with open(target_filename, "rb") as target_file:
        target_data = target_file.read()

    target_data = list(target_data)
    bootsector_data = list(bootsector_data)

    target_data[:1024] = bootsector_data

    target_data = bytes(target_data)

    with open(target_filename, "wb") as target_file:
        target_file.write(target_data)

    logging.info("Finished writing")
        


if __name__ == "__main__":
    main(len(sys.argv), sys.argv)
