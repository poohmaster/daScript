options gen2
require dastest/testing_boost
require daslib/strings_boost
require daslib/faker
require daslib/fuzzer

[test]
def test_builder(t : T?) {
    // TODO: manually test builder

    t |> run("fuzz write") @@(t : T?) {
        var fake <- Faker()
        fuzz() {
            build_string() $(writer) {
                let str = fake |> any_string
                writer |> write(str)
            }
        }
    }

    t |> run("fuzz write_char") @@(t : T?) {
        var fake <- Faker()
        fuzz() {
            build_string() $(writer) {
                // TODO: implement all different formats?
                let Ch = fake |> random_int
                writer |> write_char(Ch)
            }
        }
    }

    t |> run("fuzz write_chars") @@(t : T?) {
        var fake <- Faker()
        fuzz() {
            build_string() $(writer) {
                let Ch = fake |> random_int
                let Count = fake |> random_int % 100
                writer |> write_chars(Ch, Count)
            }
        }
    }

    t |> run("fuzz write_escape_string") @@(t : T?) {
        var fake <- Faker()
        fuzz() {
            build_string() $(writer) {
                let str = fake |> any_string
                writer |> write_escape_string(str)
            }
        }
    }

    t |> run("erase_front basic") @@(t : T?) {
        let str = build_string() $(writer) {
            writer |> write("hello world")
            writer |> erase_front(6)
        }
        t |> equal(str, "world")
    }

    t |> run("erase_front zero is a no-op") @@(t : T?) {
        let str = build_string() $(writer) {
            writer |> write("hello")
            writer |> erase_front(0)
        }
        t |> equal(str, "hello")
    }

    t |> run("erase_front entire buffer") @@(t : T?) {
        let str = build_string() $(writer) {
            writer |> write("hello")
            writer |> erase_front(5)
        }
        t |> equal(length(str), 0)
    }

    t |> run("erase_front across the fixed/large buffer growth boundary") @@(t : T?) {
        // DAS_STRING_BUILDER_BUFFER_SIZE is 256 -- 2000 single-byte writes force
        // TextWriter off its on-stack fixedBuffer and onto a heap-allocated largeBuffer.
        // erase_front must work identically in both states.
        let str = build_string() $(writer) {
            for (i in range(2000)) {
                writer |> write("x")
            }
            writer |> erase_front(1990)
        }
        t |> equal(length(str), 10)
    }

    t |> run("erase_front then append continues from the shifted position") @@(t : T?) {
        let str = build_string() $(writer) {
            writer |> write("garbage")
            writer |> erase_front(7)
            writer |> write("hello")
        }
        t |> equal(str, "hello")
    }

    t |> run("fuzz erase_front") @@(tt : T?) {
        var fake <- Faker()
        fuzz() {
            build_string() $(writer) {
                let str = fake |> any_string
                writer |> write(str)
                let len = length(str)
                // erase_front hard-fails outside [0,len] by design, so the fuzzed
                // argument must stay in range -- only the written CONTENT is randomized.
                let raw = len > 0 ? (fake |> random_int) % len : 0
                let n = raw < 0 ? -raw : raw
                writer |> erase_front(n)
            }
        }
    }

    /*
    t |> run("fuzz format") @@(t : T?) {
        var fake <- Faker()
        fuzz() {
            build_string() $(writer) {
                let str = fake |> any_string
                writer |> format(str, 0)
            }
        }
    }
    */
}

