from python import Python

fn main():
    var py = Python
    var sys = py.import_module("sys")
    var pathlib = py.import_module("pathlib")

    # Add test/bindings to sys.path
    var repo_root = pathlib.Path(__file__).resolve().parent.parent
    var bindings_dir = repo_root.joinpath("test", "bindings")
    sys.path.insert(0, str(bindings_dir))

    var abi = py.import_module("pyabi")

    print("add_i32(40,2) =", abi.add_i32(40, 2))
    print("dot2f =", abi.dot2f(1.0, 2.0, 3.0, 4.0))
    print("is_positive(-1.0) =", abi.is_positive(-1.0))

    var p = abi.make_point(5, -7)
    print("manhattan(5,-7) =", abi.manhattan(p))

    print(abi.hello("Mojo"))
