#NoEnv
SetBatchLines -1

#Include <logging>
#Include <console>
#Include <optparser>
#Include <system>
#Include <string>

op_cb(pValue, no_opt = "") {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("pValue", pValue)
		_log.Input("no_opt", no_opt)
	}

	if (pValue = "is") {
		return _log.Exit(1)
	} else if (pValue = "un") {
		return _log.Exit(2)
	} else if (pValue = "sd") {
		return _log.Exit(3)
	} else if (pValue = "rc") {
		return _log.Exit(4)
	} else {
		throw Exception("Invalid operation: " pValue)
	}
}

main:
	_main := new Logger("app.venn.main")

	global G_h, G_a, G_i, G_l, G_t, G_u, G_op, G_b, G_v, G_k, G_output

	OP_NAME := ["'Intersection' A:( (*) ):B", "'Union' A:(*(*)*):B", "'Symmetric Difference' A:(*( )*):B", "'Relative Complement' A:(*( ) ):B"]

	RC := 0

	op := new OptParser("venn [options] --operation=< is | un | sd | rc > -A <file> -B <file>")
	op.Add(new OptParser.Group("General options"))
	op.Add(new OptParser.Boolean("h", "help", G_h, "This help", OptParser.OPT_HIDDEN))
	op.Add(new OptParser.Boolean("a", "ignore-all", G_a, "Ignore leading and trailing spaces`; ignore case",, false))
	op.Add(new OptParser.Boolean("i", "ignore-case", G_i, "Ignore case", OptParser.OPT_NEG, -1))
	op.Add(new OptParser.Boolean("l", "ignore-leading-spaces", G_l, "Ignore leading spaces", OptParser.OPT_NEG, -1))
	op.Add(new OptParser.Boolean("t", "ignore-trailing-spaces", G_t, "Ignore trailing spaces", OptParser.OPT_NEG, -1))
	op.Add(new OptParser.Boolean("b", "ignore-blank-lines", G_b, "Ignore blank line (default)", OptParser.OPT_NEG, true))
	op.Add(new OptParser.Boolean("u", "unique", G_u, "Only keep the first of multiple identical lines"))
	op.Add(new OptParser.Boolean("v", "verbose", G_v, "Verbose output"))
	op.Add(new OptParser.String("A", "", _set_a, "file", "File name to use as set A"), OptParser.OPT_ARG)
	op.Add(new OptParser.String("B", "", _set_b, "file", "File name to use as set B"), OptParser.OPT_ARG)
	op.Add(new OptParser.Group("`nOperations"))
	op.Add(new OptParser.Callback(0, "operation", G_op, "op_cb", "operation"
		, ["Select an operation to perform (the '*' represents the result set):"
		, ". is: " OP_NAME[1]
		, ". un: " OP_NAME[2]
		, ". sd: " OP_NAME[3]
		, ". rc: " OP_NAME[4]]))
	op.Add(new OptParser.Group("`nOutput options`n    Output will be written to console by default`n"))
	op.Add(new OptParser.String("o", "", G_output, "file", "Write matching lines to file", OptParser.OPT_ARG))
	op.Add(new OptParser.Boolean(0, "keep-file", G_k, "Append to file instead of overwriting it", false))

	try {
		args := op.Parse(System.vArgs)
		if (_main.Logs(Logger.Finest)) {
			_main.Finest("G_h", G_h)
			_main.Finest("G_a", G_a)
			_main.Finest("G_i", G_i)
			_main.Finest("G_l", G_l)
			_main.Finest("G_t", G_t)
			_main.Finest("G_b", G_b)
			_main.Finest("G_u", G_u)
			_main.Finest("G_v", G_v)
			_main.Finest("_set_a", _set_a)
			_main.Finest("_set_b", _set_b)
			_main.Finest("G_op", G_op)
			_main.Finest("G_output", G_output)
			_main.Finest("G_k", G_k)
		}
		if (args.MinIndex() <> "")
			throw Exception("error: Invalid argument(s): " Arrays.ToString(args, "; "))
		if (G_h) {
			Console.Write(op.Usage() "`n")
		} else {
			if (!FileExist(_set_a))
				throw Exception("error: Argument -A is an invalid file or missing")
			if (!FileExist(_set_b))
				throw Exception("error: Argument -B is an invalid file or missing")
			if (G_op.Trim() = "")
				throw Exception("error: operation is not set")
			if (G_a) {
				if (G_i)
					G_i := true
				if (G_l)
					G_l := true
				if (G_t)
					G_t := true
			}
			G_output := G_output.Trim()
			if (G_v) {
				if (G_i = true)
					Console.Write("Ignoring case`n")
				else
					Console.Write("Case sensitive`n")
				if (G_l = true)
					Console.Write("Ignoring leading spaces`n")
				if (G_t = true)
					Console.Write("Ignoring trailing spaces`n")
				if (G_b)
					Console.Write("Ignoring blank lines`n")
				if (G_u)
					Console.Write("Printing no duplicates`n")
				Console.Write("Set 'A' is " _set_a "`n")
				Console.Write("Set 'B' is " _set_b "`n")
				Console.Write("Performing operation " OP_NAME[G_op] "`n")
				if (G_output.Trim() <> "") {
					if (G_k)
						Console.Write("Appending to file " G_output "`n")
					else
						Console.Write("Overwrting file " G_output "`n")
				}
			}
			if (!G_k && G_output <> "" && FileExist(G_output)) {
				if (G_v)
					Console.Write("Deleting existing output file " G_output "`n")
				FileDelete %G_output%
			}

			RC := do_operation(G_op, _set_a, _set_b)
		}
	} catch _ex {
		if (_main.Logs(Logger.SEVERE))
			_main.SEVERE("error: @" _ex.File "#" _ex.Line " : " _ex.Message)
		Console.Write(_ex.Message "`n")
		Console.write(op.Usage() "`n")
	}

exitapp _main.Exit(RC)


load_file(ByRef target, file_name) {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("file_name", file_name)
	}

	FileRead content, %file_name%
	sort_option := (G_i = true ? "" : "C")
	if (_log.Logs(Logger.Finest)) {
		_log.Finest("G_i", G_i)
		_log.Finest("sort_option = " sort_option)
	}
	Sort content, %sort_option%
	target := []
	loop Parse, content, "`n", % Chr(26)
	{
		if (!G_b || A_LoopField.Trim() <> "")
			target.Insert(A_LoopField)
	}

	if (_log.Logs(Logger.Output)) {
		_log.Output("target", target)
		if (_log.Logs(Logger.ALL))
			_log.ALL("target:`n" LoggingHelper.Dump(target))
	}

	return _log.Exit()
}

do_operation(op, file_A, file_B) {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("op", op)
		_log.Input("file_A", file_A)
		_log.Input("file_B", file_B)
	}
	
	load_file(A, file_A)
	load_file(B, file_B)

	i_A := A.MinIndex()
	i_B := B.MinIndex()
	A.Insert(Chr(255))
	B.Insert(Chr(255))
	
	n := 0
	while (i_A < A.MaxIndex() || i_B < B.MaxIndex()) {
		while (compare(A[i_A], B[i_B]) < 0 && i_A <= A.MaxIndex()) {
			if (op = 2 || op = 3 || op = 4)
				output(A[i_A], n)
			i_A++
		}
		while (compare(B[i_B], A[i_A]) < 0 && i_B <= B.MaxIndex()) {
			if (op = 2 || op = 3)
				output(B[i_B], n)
			i_B++
		}
		while (compare(A[i_A], B[i_B]) = 0 && (i_A <= A.MaxIndex() || i_B <= B.MaxIndex())) {
			if (op = 1 || op = 2) {
				output(A[i_A], n)
				output(B[i_B], n)
			}
			i_A++
			i_B++
		}
	}

	return _log.Exit(n)
}

output(pValue, ByRef count) {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("pValue", pValue)
		_log.Input("count", count)
	}

	static last_value = ""

	if (pValue = Chr(255) || (G_u && pValue == last_value))
		return

	if (G_output <> "")
		FileAppend %pValue% "`n", %G_output%
	else
		Console.Write(pValue "`n")
	last_value := pValue
	count++

	if (_log.Logs(Logger.Output))
		_log.Output("count", count)

	return _log.Exit()
}

compare(elem_A, elem_B) {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("elem_A", elem_A)
		_log.Input("elem_B", elem_B)
	}

	if (G_l && G_t) {
		elem_A := elem_A.Trim(String.TRIM_ALL)
		elem_B := elem_B.Trim(String.TRIM_ALL)	
	} else if (G_l) {
		elem_A := elem_A.Trim(String.TRIM_LEFT)
		elem_B := elem_B.Trim(String.TRIM_LEFT)
	} else if (G_t) {
		elem_A := elem_A.Trim(String.TRIM_RIGHT)
		elem_B := elem_B.Trim(String.TRIM_RIGHT)
	}

	return _log.Exit(elem_A.Compare(elem_B, (G_i = true ? false : true)))
}