#!/bin/bash

# Copyright 2013, Raphael Reitzig
# <code@verrech.net>
#
# pdfsplitk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pdfsplitk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pdfsplitk. If not, see <http://www.gnu.org/licenses/>.

# Splits PDFs into constant-sized chunks.
# Requires `pdftk`, `pdfinfo`, `awk` and `acroread` if PS output is desired.
#
# Call with four parameters:
#  * First is the input file (`*.pdf`).
#  * Second it the number of pages per chunk.
#  * Third is the target directory.
#  * Fourth is `ps` if you want PS instead of PDF output (optional).
#
# Original hosted at https://github.com/reitzig/scripts/blob/master/pdfsplitk]
#
# Modified 1/23/2018
# by Patrick J. Burns (patrick@diyclassics.org)
#
# PJB Changelog
# - Changed filename to read only the filename, not the path; this 
# allows cleaner interaction with files that are not in the same
# path as the script
# - Added a feature for printing "remainder" pages; i.e. if a pdf is 
# 12 pages long and you want it divided into groups of 5, the output
# will be 3 pdfs total (2 5-page pdfs and 1 2-page pdf)

if [ ${#} -lt 3 ];
then
  echo "Usage: pdfsplitk <file.pdf> <pages per chunk> <target dir> [ps]";
  exit;
fi

declare -i pagesper number count counter start end;

tmp="/tmp/pdfsplitk";
file=$1;
filename=$(basename "$1");
pagesper=$2;
target=$3;
mode=$4;

if [[ ! -d "${target}" ]]; then
  mkdir "${target}";
fi

if [[ -d "${target}" ]]; then
  mkdir ${tmp};
  cp $file ${tmp}/;
  
  number=$(pdfinfo "${tmp}/${filename}" 2>&1 | grep Pages | awk ' /\ddd+/; { print $2 }');
  count=$((number / pagesper));
  remainder=$((number % pagesper))
  
  if (( remainder == 0 )); then
    extra=false;
  else
    echo False;
    extra=true;   
  fi
  
  echo "[pdfsplitk] Creating ${count} documents with ${pagesper} pages each in ${target}.";
  echo "";

  counter=0;
  while [[ $count -gt $counter ]]; do 
    echo -e "\033M[$((100*counter/count))%]";
    start=$((counter*pagesper + 1));
    end=$((start + pagesper - 1));
    
    counterstring=`printf '%04d' ${counter}`;
    if [[ ${mode} == "ps" ]]; then      
      acroread -toPostScript -size a4 -start ${start} -end ${end} -pairs "${tmp}/${file}" "${target}/${filename}_${counterstring}.ps";
    else
      pdftk "${tmp}/${filename}" cat ${start}-${end} output "${target}/${filename}_${counterstring}.pdf";
    fi
    
    counter=$((counter + 1));
  done
  
  if ((extra == true)); then
    echo "[pdfsplitk] Creating 1 documents with ${remainder} pages in ${target}.";
    echo "";
    counterstring=`printf '%04d' ${counter}`;
    start=$((number-remainder+1));
    end=$((start+remainder-1));
    pdftk "${tmp}/${filename}" cat ${start}-${end} output "${target}/${filename}_${counterstring}.pdf";  
  fi
  
  echo -e "\033M[Done]";
  
  rm -rf ${tmp};
fi
