
createNewReactiveRepository = (liveRepository) ->
	liveRepo = liveRepository
	repo =
		documents: []
		liveRepo: liveRepo
	repo.reactiveProperty =
		new reactive.property repo
	repo.documents.createWithContent = () ->
		repo.documents.push liveRepo.documents.createWithContent()
		repo.reactiveProperty.reactTo repo


olw.reactiveRepository =
	create: -> createNewReactiveRepository(olw.repository.create)
