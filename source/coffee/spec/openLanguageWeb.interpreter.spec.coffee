describe "open language web", () ->

	describe "interpreter", () ->
	
		exampleObj0 =
			f0: () -> "content"
		
		exampleObj1 =
			f0: (txt) -> "(" + txt + ")"
			f1: (a, b) -> a + b
		
		it "can interpret an empty document", () ->			
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), () ->
				@content()
			result = olw.interpreter.interpret(doc)
			expect(result).toEqual([])

		describe "interpret atomic javascript values", () ->
			
			repo = olw.withBuilders(olw.repository.create())

			it "can interpret an int value", () ->
				{document: doc} = using repo.standardDocument().referencing(), ->
					@content(@int(2))
				result = olw.interpreter.interpret(doc)
				expect(result).toEqual([2])

			it "can interpret a string value", () ->
				{document: doc} = using repo.standardDocument().referencing(), ->
					@content(@string("expected"))
				result = olw.interpreter.interpret(doc)
				expect(result).toEqual(["expected"])
		
		describe "interpret atomic javascript values from raw storage", () ->
		
			repo = olw.withBuilders(olw.repository.create())
			storage = repo.storage
			
			it "can interpret an int value", () ->
				{document: doc} = using repo.standardDocument().referencing(), ->
					@content(@int(2))
				result = olw.interpreter.interpretStoredDoc(
					repo, doc.id, doc.version)
				expect(result).toEqual([2])

			it "can interpret a string value", () ->
				{document: doc} = using repo.standardDocument().referencing(), ->
					@content(@string("expected"))
				result = olw.interpreter.interpretStoredDoc(
					repo, doc.id, doc.version)
				expect(result).toEqual(["expected"])

		it "can interpret multiple argument expressions from bootstrap", () ->
			repo = olw.withBuilders(olw.repository.create())
			bootstrap = repo.documents.bootstrap(exampleObj1, "any url")
			{document: doc} = using repo.standardDocument().referencing(bootstrap), ->
				@content(@f1(@int(3), @int(4)))
			result = olw.interpreter.interpret(doc)
			expect(result).toEqual([7])

		it "can interpret doc referencing nodes in another standard doc", () ->
			repo = olw.withBuilders(olw.repository.create())
			bootstrap = repo.documents.bootstrap(exampleObj1, "any url")
			doc1 = using repo.standardDocument().withUrl("any other url").referencing(bootstrap), ->
				@content(
					@ref("r1", @int(3)),
					@ref("r2", @f1(@int(4), @int(5)))
				)
			doc2 = using repo.standardDocument().referencing(bootstrap, doc1), ->
				@content(
					@f1(@r1(), @r2())
				)
			result = olw.interpreter.interpret(doc2.document)
			expect(result).toEqual([12])
			
		
		it "can can produce a result with a unique identity when a node" +
		   " is referenced in multiple locations (by caching the interpreted result)", () ->
			repo = olw.withBuilders(olw.repository.create())
			v = 0
			obj =
				myInt: () ->
					v = v+1
					v
			bootstrap = repo.documents.bootstrap(obj, "any url")
			{document: doc} = using repo.standardDocument().referencing(bootstrap), ->
				intVal = @myInt()
				@content(intVal,@nodeReference(intVal.id, intVal))
			result = olw.interpreter.interpret(doc)
			expect(result).toEqual([1, 1])
