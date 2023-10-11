#!/bin/bash -e
#SBATCH -A massey03262
#SBATCH -J mosaic  
#SBATCH --time 100:00:00 # walltime
#SBATCH --mem 256GB # Memory in MB or GB
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 4
#SBATCH -e mosaic.err
#SBATCH -o mosaic.out
#SBATCH --export NONE
#SBATCH --mail-type=end         
#SBATCH --mail-type=fail         
#SBATCH --mail-user=r.delaramuylaert@massey.ac.nz

cd /nesi/nobackup/massey03262/
   
module load R/4.3.1-gimkl-2022a
module load R-Geo/4.3.1-gimkl-2022a

R --vanilla <<EOF
source("mosaic_globcover.R")
q()
EOF

echo "Completed"