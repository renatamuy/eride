import argparse
import numpy as np
import pandas as pd
from tqdm import tqdm
from PIL import Image
import rasterio
from multiprocessing import Pool, cpu_count

def count_cell_values(args):
    image_file, output_file, row_index = args

    # Open the raster image using rasterio
    with rasterio.open(image_file) as dataset:
        # Read the specified row of the image data using rasterio
        image = dataset.read(window=((row_index, row_index + 1), slice(None)))

    # Get the unique cell values and their counts
    cell_values, cell_counts = np.unique(image, return_counts=True)

    # Count the number of each cell value
    counts = {}
    for value, count in zip(cell_values, cell_counts):
        counts[value] = count

    return counts

def main(image_file, output_file):
    # Adjust the maximum image pixels limit in PIL
    Image.MAX_IMAGE_PIXELS = None

    # Open the image with PIL
    image = Image.open(image_file)

    # Get the image height
    height = image.size[1]

    # Determine the number of processes to use
    num_processes = max(cpu_count() - 2, 1)  # At least 1 process

    # Create a list of row indices to process
    row_indices = list(range(height))

    # Create argument tuples for each row
    args_list = [(image_file, output_file, row_index) for row_index in row_indices]

    # Create a multiprocessing pool with the specified number of processes
    pool = Pool(processes=num_processes)

    # Map the count_cell_values function to the argument tuples in parallel
    results = []
    for res in tqdm(pool.imap_unordered(count_cell_values, args_list), total=len(row_indices), desc='Processing'):
        results.append(res)

    # Close the pool and wait for the processes to finish
    pool.close()
    pool.join()

    # Combine the results from all processes
    counts = {}
    for res in results:
        for value, count in res.items():
            counts.setdefault(value, 0)
            counts[value] += count

    # Remove the row with the value "4294967295"
    if 4294967295 in counts:
        del counts[4294967295]

    # Save the counts to a tab-delimited file without header
    with open(output_file, 'w') as file:
        for value, count in counts.items():
            file.write(f'{value} = {count}\n')

if __name__ == '__main__':
    # Create an argument parser
    parser = argparse.ArgumentParser(description='Count the number of each cell value in an image.')
    parser.add_argument('image_file', type=str, help='Path to the image file')
    parser.add_argument('output_file', type=str, help='Path to the output file')

    # Parse the command-line arguments
    args = parser.parse_args()

    # Extract the image file and output file
    image_file = args.image_file
    output_file = args.output_file

    # Call the main function to perform parallel processing
    main(image_file, output_file)

