;@Ahk2Exe-ConsoleApp
class Venn {

	requires() {
		return [Ansi, OptParser, System, String, Arrays]
	}

	static opts := Venn.setDefaults()
	static OP_NAME
			:= [ "'Intersection' A:( (*) ):B"
			, "'Union' A:(*(*)*):B"
			, "'Symmetric Difference' A:(*( )*):B"
			, "'Relative Complement' A:(*( ) ):B" ]

	setDefaults() {
		dv := { ignoreAll: false
				, ignoreBlankLines: true
				, encodingOfFileA: "cp1252"
				, encodingOfFileB: "cp1252"
				, help: false
				, ignoreCase: -1
				, keepFile: false
				, ignoreLeadingSpaces: -1
				, operation: ""
				, output: false
				, output_file: ""
				, printSource: false
				, setA: ""
				, setB: ""
				, ignoreTrailingSpaces: -1
				, unique: false
				, verboseOutput: false
				, version: false
				, count: 0}
		Venn.opts := dv
	}

	doOperation(operation, fileA, fileB, compareAsType=0) {
		Venn.handleIgnoreAll()
		A := Venn.loadFileIntoArray(fileA, Venn.opts.encodingOfFileA)
		B := Venn.loadFileIntoArray(fileB, Venn.opts.encodingOfFileB)
		count := 0
		try {
			Venn.handleOutput()
			switch operation {
			case 1:
				resultSet := new Arrays.Intersection(A, B
						, Venn.handleIgnoreCase(), Venn.opts.printSource)
						.result()
			case 2:
				resultSet := new Arrays.Union(A, B
						, Venn.handleIgnoreCase(), Venn.opts.printSource)
						.result()
			case 3:
				resultSet := new Arrays.SymmetricDifference(A, B
						, Venn.handleIgnoreCase(), Venn.opts.printSource)
						.result()
			case 4:
				resultSet := new Arrays.RelativeComplement(A, B
						, Venn.handleIgnoreCase(), Venn.opts.printSource)
						.result()
			}
			while (A_Index <= resultSet.maxIndex()) {
				count := Venn.output(resultSet[A_Index])
			}
		} finally {
			if (Venn.opts.output_file != "") {
				Venn.opts.output_file.close()
			}
		}
		return count
	}

	loadFileIntoArray(fileName, encoding="utf-8") {
		FileGetSize sizeOfInputFileInBytes, %fileName%
		inputFile := FileOpen(fileName, "r`n", encoding)
		contentOfInputFile := inputFile.read(sizeOfInputFileInBytes)
		inputFile.close()
		sortOption := (Venn.opts.ignoreCase = true ? "" : "C")
		Sort contentOfInputFile, %sortOption%
		target := []
		loop Parse, contentOfInputFile, % "`n", % Chr(26)  ; NOWARN
		{
			if (!Venn.opts.ignoreBlankLines || A_LoopField.trimAll() != "") {
				target.push(A_LoopField)
			}
		}
		return target
	}

	compareIgnoreCase(aString, anotherString) {
		aString := Format("{:U}", aString) "$"
		anotherString := Format("{:U}", anotherString) "$"
		return (aString == anotherString ? 0
				: aString > anotherString ? +1 : -1)
	}

	handleOutput() {
		if (Venn.opts.output != "") {
			if (Venn.opts.keepFile) {
				Venn.opts.output_file := FileOpen(Venn.opts.output, "a")
			} else {
				Venn.opts.output_file := FileOpen(Venn.opts.output, "w")
			}
		}
	}

	handleIgnoreCase() {
		if (Venn.opts.ignoreCase == true) {
			return Venn.compareIgnoreCase.bind(Venn)
		}
		return ""
	}

	handleIgnoreAll() {
		if (Venn.opts.ignoreAll) {
			if (Venn.opts.ignoreCase != 0) {
				Venn.opts.ignoreCase := true
			}
			if (Venn.opts.ignoreLeadingSpaces != 0) {
				Venn.opts.ignoreLeadingSpaces := true
			}
			if (Venn.opts.ignoreTrailingSpaces != 0) {
				Venn.opts.ignoreTrailingSpaces := true
			}
		}
	}

	output(currentValue) {
		if (!(Venn.opts.unique && Venn.isSameValueAsPrevious(currentValue))) {
			if (Venn.opts.output != "") {
				Venn.opts.output_file.writeLine(currentValue)
			} else {
				Ansi.writeLine(currentValue)
			}
			Venn.opts.count++
		}
		return Venn.opts.count
	}

	isSameValueAsPrevious(currentValue) {
		static previousValue := ""
		result := (Venn.opts.ignoreCase = true
				? currentValue = previousValue
				: currentValue == previousValue)
		previousValue := currentValue
		return result
	}

	cli() {
		op := new OptParser("venn [options] "
				. "--operation=< is | un | sd | rc > -A <file> -B <file>")
		op.add(new OptParser.Group("General options"))
		op.add(new OptParser.Boolean("h", "help", Venn.opts
				, "help", "This help"
				, OptParser.OPT_HIDDEN))
		op.add(new OptParser.Boolean("a", "ignore-all"
				, Venn.opts, "ignoreAll"
				, "Ignore leading and trailing spaces`; ignore case"
				,, false))
		op.add(new OptParser.Boolean("i", "ignore-case", Venn.opts
				, "ignoreCase", "Ignore case"
				, OptParser.OPT_NEG, -1))
		op.add(new OptParser.Boolean("l", "ignore-leading-spaces", Venn.opts
				, "ignoreLeadingSpaces", "Ignore leading spaces"
				, OptParser.OPT_NEG, -1))
		op.add(new OptParser.Boolean("t", "ignore-trailing-spaces", Venn.opts
				, "ignoreTrailingSpaces", "Ignore trailing spaces"
				, OptParser.OPT_NEG, -1))
		op.add(new OptParser.Boolean("b", "ignore-blank-lines", Venn.opts
				, "ignoreBlankLines", "Ignore blank line (default)"
				, OptParser.OPT_NEG, true))
		op.add(new OptParser.Boolean("u", "unique", Venn.opts
				, "unique", "Only keep the first of multiple identical lines"))
		op.add(new OptParser.Boolean("s", "source", Venn.opts
				, "printSource", "Print source (A/B) in results"))
		op.add(new OptParser.Boolean("v", "verbose", Venn.opts
				, "verboseOutput", "Verbose output"))
		op.add(new OptParser.Boolean(0, "version", Venn.opts
				, "version", "Version info"))
		op.add(new OptParser.String(0, "enc-A", Venn.opts
				, "encodingOfFileA", "encoding", "Encoding of file A"
				, OptParser.OPT_ARG,, Venn.opts.encodingOfFileA))
		op.add(new OptParser.String(0, "enc-B", Venn.opts
				, "encodingOfFileB", "encoding", "Encoding fo file B"
				, OptParser.OPT_ARG,, Venn.opts.encodingOfFileB))
		op.add(new Optparser.Group("`nSets"))
		op.add(new OptParser.String("A", "", Venn.opts
				, "setA", "file", "File name to use as set A"
				, OptParser.OPT_ARG))
		op.add(new OptParser.String("B", "", Venn.opts
				, "setB", "file", "File name to use as set B"
				, OptParser.OPT_ARG))
		op.add(new OptParser.Group("`nOperations"))
		op.add(new OptParser.Callback(0, "operation", Venn.opts
				, "operation", "operation_cb", "operation"
				, [ "Select an operation to perform"
				. " (the '*' represents the result set):"
				, ". is: " Venn.OP_NAME[1]
				, ". un: " Venn.OP_NAME[2]
				, ". sd: " Venn.OP_NAME[3]
				, ". rc: " Venn.OP_NAME[4] ]))
		op.add(new OptParser.Group("`nOutput options`n    "
				. "Output will be written to console by default`n"))
		op.add(new OptParser.String("o", "", Venn.opts
				, "output", "file", "Write matching lines to file"
				, OptParser.OPT_ARG))
		op.add(new OptParser.Boolean(0, "keep-file", Venn.opts
				, "keepFile", "Append to file instead of overwriting it"
				, false))
		return op
	}

	; @todo: Refactor!
	run(args) {
		Venn.setDefaults()
		returnCode := 0
		try {
			op := Venn.cli()
			args := op.parse(args)
			if (args.minIndex() != "") {
				throw Exception("error: Invalid argument(s): "
						. Arrays.toString(args, "; "))
			}
			if (Venn.opts.help) {
				Ansi.writeLine(op.usage())
			} else if (Venn.opts.version) {
				G_VERSION_INFO := { NAME: "AHK venn version v0.0.0"
						, ARCH: "x" (A_PtrSize = 4 ? "86" : "64")
						, BUILD: A_YYYY A_MM A_DD A_Hour A_Min }
				#Include *i %A_ScriptDir%\.versioninfo
				Ansi.writeLine(G_VERSION_INFO.NAME
						. "/" G_VERSION_INFO.ARCH
						. "-" G_VERSION_INFO.BUILD)
			} else {
				if (!FileExist(Venn.opts.setA)) {
					throw Exception("error: Argument -A is an invalid file "
							. "or missing")
				}
				if (!FileExist(Venn.opts.setB)) {
					throw Exception("error: Argument -B is an invalid file "
							. "or missing")
				}
				Venn.opts.output := Venn.opts.output.trimAll()
				if (Venn.opts.verboseOutput) {
					if (Venn.opts.ignoreCase = true
							|| Venn.opts.ignoreAll = true) {
						Ansi.write("Ignoring case`n")
					} else {
						Ansi.write("Case sensitive`n")
					}
					if (Venn.opts.ignoreLeadingSpaces = true
							|| Venn.opts.ignoreAll = true) {
						Ansi.write("Ignoring leading spaces`n")
					}
					if (Venn.opts.ignoreTrailingSpaces = true
							|| Venn.opts.ignoreAll = true) {
						Ansi.write("Ignoring trailing spaces`n")
					}
					if (Venn.opts.ignoreBlankLines) {
						Ansi.write("Ignoring blank lines`n")
					}
					if (Venn.opts.unique) {
						Ansi.write("Printing no duplicates`n")
					}
					Ansi.write("Set 'A' is " Venn.opts.setA
							. " with encoding " Venn.opts.encodingOfFileA "`n")
					Ansi.write("Set 'B' is " Venn.opts.setB
							. " with encoding " Venn.opts.encodingOfFileB "`n")
					Ansi.write("Performing operation "
							. Venn.OP_NAME[Venn.opts.operation] "`n")
					if (Venn.opts.output.trimAll() != "") {
						if (Venn.opts.keepFile) {
							Ansi.write("Appending to file "
									. Venn.opts.output "`n")
						} else {
							Ansi.write("Overwrting file "
									. Venn.opts.output "`n")
						}
					}
				}
				returnCode := Venn.doOperation(Venn.opts.operation
						, Venn.opts.setA, Venn.opts.setB)
			}
		} catch _ex {
			Ansi.write(_ex.message "`n")
			Ansi.write(op.usage() "`n")
		}
		return returnCode
	}
}

operation_cb(operation, noOption="") {
	static Operations := {is: 1, un: 2, sd: 3, rc: 4}
	if (!Operations.hasKey(operation)) {
		throw Exception("Invalid operation: " operation)
	}
	return Operations[operation]
}

#NoEnv ; notest-begin
#Warn All, StdOut
SetBatchLines -1

#Include <app>
#Include <cui-libs>
#Include <system>

exitapp App.checkRequiredClasses(Venn).run(A_Args) ; notest-end
