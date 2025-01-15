# by CHEN Hao

data=$(ls -d /scratch7/MINDLAB2016_MR-SensCogFromNeural/results/mrtrix3/sub-* | grep -P '\d+$' -o)
for d in $data
do
	# if [[ "$d">"0310" ]];
	# then
		echo $d
		sh gen_connectome.sh $d
	# fi
done
