_site/:
	bundle exec jekyll build

clean:
	rm -rf _site

deps:
	bundle install

publish-dry:
	aws s3 sync --dryrun --exclude=.DS_Store _site/ s3://blog.nfi.io

publish:
	aws s3 sync --exclude=.DS_Store _site/ s3://blog.nfi.io

view:
	( sleep 5 ; open http://localhost:4000 ) &
	bundle exec jekyll serve 
