; ahk: console
#NoEnv
#Warn All, StdOut
SetBatchLines -1

#Include <app>
#Include <testcase-libs>

class VennTest extends TestCase {

	requires() {
		return [TestCase, Venn]
	}

	static FILE_A := A_Temp "\venn_A.txt"
	static FILE_B := A_Temp "\venn_B.txt"
	static FILE_RES := A_Temp "\venn_result.txt"
	static FILE_CON := A_Temp "\venn_test.txt"

	@BeforeClass_setup() {
		if (FileExist(VennTest.FILE_A)) {
			FileDelete, % VennTest.FILE_A
		}
		if (FileExist(VennTest.FILE_B)) {
			FileDelete, % VennTest.FILE_B
		}
		FileAppend,
			( LTrim
				i
				H
				f
				C
				B
				A
			), % VennTest.FILE_A
		FileAppend,
			( LTrim
				I
				G
				f
				e
				D
				C
				A
			), % VennTest.FILE_B
		if (!FileExist(VennTest.FILE_A)) {
			this.fail("File not found: " VennTest.FILE_A)
		}
		if (!FileExist(VennTest.FILE_B)) {
			this.fail("File not found: " VennTest.FILE_B)
		}
	}

	@AfterClass_teardown() {
		if (FileExist(VennTest.FILE_A)) {
			FileDelete, % VennTest.FILE_A
		}
		if (FileExist(VennTest.FILE_B)) {
			FileDelete, % VennTest.FILE_B
		}
		if (FileExist(VennTest.FILE_RES)) {
			FileDelete, % VennTest.FILE_RES
		}
	}

	@Before_setup() {
        Venn.setDefaults()
		Venn.opts.output := VennTest.FILE_RES
		Venn.opts.output_file := FileOpen(Venn.opts.output, "w")
	}

	@After_teardown() {
		Venn.opts.close()
	}

	@BeforeRedirStdOut() {
		Ansi.stdOut := FileOpen(VennTest.FILE_CON, "w")
	}

	@AfterRedirStdOut() {
		Ansi.stdOut.close()
		Ansi.stdOut := Ansi.__InitStdOut()
		FileDelete, % VennTest.FILE_CON
	}

	@Test_loadFileA() {
		A := Venn.loadFileIntoArray(A_Temp "\venn_A.txt")
		this.assertEquals(A.maxIndex(), 6)
		this.assertTrue(Arrays.equal(A, ["A", "B", "C", "H", "f", "i"]))
	}

	@Test_loadFileB() {
		B := Venn.loadFileIntoArray(A_Temp "\venn_B.txt")
		this.assertEquals(B.maxIndex(), 7)
		this.assertTrue(Arrays.equal(B, ["A", "C", "D", "G", "I", "e", "f"]))
	}

    @Test_opCallback() {
        this.assertEquals(operation_cb("is"), 1)
        this.assertEquals(operation_cb("un"), 2)
        this.assertEquals(operation_cb("sd"), 3)
        this.assertEquals(operation_cb("rc"), 4)
        this.assertException("", "operation_cb", "", "", "xx")
    }

	@Test_union() {
		res := Venn.doOperation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 13)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252")
				, ["A", "A", "B", "C", "C", "D", "G"
				, "H", "I", "e", "f", "f", "i"]))
	}

	@Test_unionUnique() {
		Venn.opts.unique := true
		res := Venn.doOperation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 10)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252")
				, ["A", "B", "C", "D", "G", "H", "I", "e", "f", "i"]))
	}

	@Test_unionUniqueIgnoreCase() {
		Venn.opts.unique := true
		Venn.opts.ignoreCase := true
		res := Venn.doOperation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 9)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252")
				, ["A", "B", "C", "D", "e", "f", "G", "H", "i"]))
	}

	@Test_intersection() {
		res := Venn.doOperation(1, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 6)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252")
				, ["A", "A", "C", "C", "f", "f"]))
	}

	@Test_intersectionWithSource() {
		Venn.opts.printSource := true
		res := Venn.doOperation(1, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 6)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252")
				, ["(A) A", "(B) A", "(A) C", "(B) C", "(A) f", "(B) f"]))
	}

	@Test_intersectionUnique() {
		Venn.opts.unique := true
		res := Venn.doOperation(1, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 3)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["A", "C", "f"]))
	}

	@Test_intersectionUniqueIgnoreCase() {
		Venn.opts.unique := true
		Venn.opts.ignoreCase := true
		res := Venn.doOperation(1, VennTest.FILE_A, VennTest.FILE_B
				, String.COMPARE_AS_STRING)
		OutputDebug % LoggingHelper.dump(res)
		this.assertEquals(res, 4)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["A", "C", "f", "i"]))
	}

	@Test_symDiff() {
		res := Venn.doOperation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 7)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["B", "D", "G", "H", "I", "e", "i"]))
	}

	@Test_symDiffUnique() {
		Venn.opts.unique := true
		res := Venn.doOperation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 7)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["B", "D", "G", "H", "I", "e", "i"]))
	}

	@Test_symDiffUniqueIgnoreCase() {
		Venn.opts.unique := true
		Venn.opts.ignoreCase := true
		res := Venn.doOperation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 5)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["B", "D", "e", "G", "H"]))
	}

	@Test_relCompAB() {
		res := Venn.doOperation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 3)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["B", "H", "i"]))
	}

	@Test_relCompBA() {
		res := Venn.doOperation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.assertEquals(res, 4)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["D", "G", "I", "e"]))
	}

	@Test_relCompUniqueAB() {
		Venn.opts.unique := true
		res := Venn.doOperation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 3)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["B", "H", "i"]))
	}

	@Test_relCompUniqueBA() {
		Venn.opts.unique := true
		res := Venn.doOperation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.assertEquals(res, 4)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["D", "G", "I", "e"]))
	}

	@Test_relCompUniqueIgnoreCaseAB() {
		Venn.opts.unique := true
		Venn.opts.ignoreCase := true
		res := Venn.doOperation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.assertEquals(res, 2)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["B", "H"]))
	}

	@Test_relCompUniqueIgnoreCaseBA() {
		Venn.opts.unique := true
		Venn.opts.ignoreCase := true
		res := Venn.doOperation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.assertEquals(res, 3)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["D", "e", "G"]))
	}

	@Test_portalAbrechnung() {
		if (FileExist(A_Temp "\blacklist.txt")) {
			FileDelete, % A_Temp "\blacklist.txt"
		}
		if (FileExist(A_Temp "\users.txt")) {
			FileDelete, % A_Temp "\users.txt"
		}
		FileAppend,
			( LTrim
				thac
				scdd
			), % A_Temp "\blacklist.txt"
		FileAppend,
			( LTrim
				BChr
				scdd
				heap
				ScdD
				ThaC
				zahl
			), % A_Temp "\users.txt"
		Venn.opts.unique := true
		Venn.opts.ignoreAll := true
		res := Venn.doOperation(4, A_Temp "\users.txt", A_Temp "\blacklist.txt")
		this.assertEquals(res, 3)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["BChr", "heap", "zahl"]))
	}

	@Test_portalAbrechnungStelle2() {
		if (FileExist(A_Temp "\blacklist.txt")) {
			FileDelete, % A_Temp "\blacklist.txt"
		}
		if (FileExist(A_Temp "\users.txt")) {
			FileDelete, % A_Temp "\users.txt"
		}
		FileAppend,
			( LTrim
				thac
				scdd
			), % A_Temp "\blacklist.txt"
		FileAppend,
			( LTrim
				BChr
				scdd
				heap
				ScdD
				ThaC
				zahl
			), % A_Temp "\users.txt"
		Venn.opts.unique := true
		Venn.opts.ignoreAll := true
		Venn.opts.compare_at := 1
		res := Venn.doOperation(4, A_Temp "\users.txt", A_Temp "\blacklist.txt")
		this.assertEquals(res, 3)
		this.assertTrue(Arrays.equal(load_file_into_array(VennTest.FILE_RES
				, "cp1252"), ["BChr", "heap", "zahl"]))
	}

	@Test_usage() {
		this.assertEquals(Venn.run(["-h"]), 0)
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(VennTest.FILE_CON)
				, TestCase.fileContent(A_ScriptDir "\figures\Usage.txt"))
	}

	@Test_versionInfo() {
		this.assertEquals(Venn.run(["--version"]), 0)
		Ansi.flush()
		this.assertTrue(RegExMatch(TestCase.fileContent(VennTest.FILE_CON)
				, "AHK venn version v0\.0\.0/.*"))
	}

	@Test_example1() {
		this.assertEquals(Venn.run(["-s", "--operation", "un", "-A"
				, VennTest.FILE_A, "-B", VennTest.FILE_B]), 13)
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(VennTest.FILE_CON)
				, TestCase.fileContent(A_ScriptDir
				. "\figures\UnionWithSource.txt"))
	}

	@Test_example2() {
		if (FileExist(A_Temp "\venn-test.txt")) {
			FileDelete %A_Temp%\venn-test.txt
		}
		FileAppend TEST`n, %A_Temp%\venn-test.txt
		this.assertEquals(Venn.run(["--keep-file", "-o", A_Temp "\venn-test.txt"
				, "--operation", "un", "-A", VennTest.FILE_A
				, "-B", VennTest.FILE_B]), 13)
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\venn-test.txt")
				, "TEST`r`nA`nA`nB`nC`nC`nD`nG`nH`nI`ne`nf`nf`ni`n")
		if (FileExist(A_Temp "\venn-test.txt")) {
			FileDelete %A_Temp%\venn-test.txt
		}
	}

	@Test_example3() {
		this.assertEquals(Venn.run(["--operation", "un", "-lu"
				, "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 10)
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(VennTest.FILE_CON)
				, TestCase.fileContent(A_ScriptDir "\figures\UniqueUnion.txt"))
	}

	@Test_example4() {
		this.assertEquals(Venn.run(["--operation", "un", "-tu"
				, "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 10)
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(VennTest.FILE_CON)
				, TestCase.fileContent(A_ScriptDir "\figures\UniqueUnion.txt"))
	}

	@Test_example5() {
		this.assertEquals(Venn.run(["--operation", "un", "-auv"
				, "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 9)
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(VennTest.FILE_CON)
				, TestCase.fileContent(A_ScriptDir
				. "\figures\UniqueUnionIgnoreAll.txt"))
	}

	@Test_example6() {
		if (FileExist(A_Temp "\venn-test.txt")) {
			FileDelete %A_Temp%\venn-test.txt
		}
		this.assertEquals(Venn.run(["--operation", "un", "-v", "-o"
				, A_Temp "\venn-test.txt"
				, "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 13)
		this.assertEquals(Venn.run(["--operation", "un", "-vu", "-o"
				, A_Temp "\venn-test.txt", "--keep-file"
				, "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 10)
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\venn-test.txt")
				, "A`nA`nB`nC`nC`nD`nG`nH`nI`ne`nf`nf`ni`nA`nB`nC`nD`nG`nH`nI`ne`nf`ni`n") ; ahklint-ignore: W002
		this.assertEquals(TestCase.fileContent(VennTest.FILE_CON)
				, TestCase.fileContent(A_ScriptDir
				. "\figures\VerboseCreateAppendFile.txt"))
		if (FileExist(A_Temp "\venn-test.txt")) {
			FileDelete %A_Temp%\venn-test.txt
		}
	}

	@Test_errorHandling() {
		this.assertEquals(Venn.run(["-A"]), 0)
		this.assertEquals(Venn.run(["-A", VennTest.FILE_A, "-B"]), 0)
		this.assertEquals(Venn.run(["--operation"]), 0)
		this.assertEquals(Venn.run(["--operation", "un"
				, "-A", VennTest.FILE_A, "-B", VennTest.file_B
				, "foo", "bar", "buzz"]), 0)
		this.assertEquals(Venn.run(["--operation", "un"
				, "-A", "foo.bar", "-B", VennTest.file_B]), 0)
		this.assertEquals(Venn.run(["--operation", "un"
				, "-A", VennTest.FILE_A, "-B", "foo.bar"]), 0)
		Ansi.flush()
		usage := TestCase.fileContent(A_ScriptDir "\figures\Usage.txt")
		this.assertEquals(TestCase.fileContent(VennTest.FILE_CON)
				, "Missing argument 'file'`n" usage
				. "Missing argument 'file'`n" usage
				. "Missing argument 'operation'`n" usage
				. "error: Invalid argument(s): foo; bar; buzz`n" usage
				. "error: Argument -A is an invalid file or missing`n" usage
				. "error: Argument -B is an invalid file or missing`n" usage)
	}
}

exitapp VennTest.runTests()

load_file_into_array(fileName, encoding, dump=false) {
	FileGetSize size, %fileName%
	file := FileOpen(fileName, "r `n", encoding)
	content := file.read(size)
	file.close()
	target := []
	loop Parse, content, % "`n", % Chr(26)
	{
		target.push(A_LoopField)
		if (dump) {
			OutputDebug %A_ThisFunc%: %A_Index%: %A_LoopField%
		}
	}
	target.remove() ; Removes the last (blank) element
	return target
}

#Include %A_ScriptDir%\..\venn.ahk
