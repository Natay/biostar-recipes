USER=www
DATA_DIR=/export/sites/main_data/initial
DATA_HOST=data.bioinformatics.recipes

# The initial data for all recipes
DATA_FILE=recipes-initial-data.tar.gz

all:
	@echo Valid commands: push, data_pull

# The local directory
export/local:
	mkdir -p export/local

# Make the required directories
dir: export/local

push:
	git commit -am "Update by `whoami` on `date` from `hostname`"
	git push

mothur:
	python manage.py project --json projects/metagenome/mothur-project.hjson --privacy public --jobs

data_pull: dir
	(cd export && rsync -avz ${USER}@${DATA_HOST}:${DATA_DIR}/${DATA_FILE} . )
	(cd export && tar zxvf ${DATA_FILE})

pack: dir
	(cd export && tar czvf ${DATA_FILE} local/bwa )
	(cd export && rsync -avz ${DATA_FILE} ${USER}@${DATA_HOST}:${DATA_DIR}/)
