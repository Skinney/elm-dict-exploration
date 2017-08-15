module Tests exposing (tests)

import Basics exposing (..)
import Dict as BaseDict
import Dict2 as Dict exposing (Dict)
import List
import Maybe exposing (..)
import Test exposing (..)
import Fuzz exposing (Fuzzer)
import Expect


animals : Dict.Dict String String
animals =
    Dict.fromList [ ( "Tom", "cat" ), ( "Jerry", "mouse" ) ]


fuzzPairs : Fuzzer (List ( Int, Int ))
fuzzPairs =
    ( Fuzz.int, Fuzz.constant 0 )
        |> Fuzz.tuple
        |> Fuzz.list


fuzzDict : Fuzzer (Dict Int Int)
fuzzDict =
    Fuzz.map Dict.fromList fuzzPairs


tests : Test
tests =
    let
        buildTests =
            describe "build Tests"
                [ test "empty" <| \() -> Expect.equal (Dict.fromList []) (Dict.empty)
                , test "singleton" <| \() -> Expect.equal (Dict.fromList [ ( "k", "v" ) ]) (Dict.singleton "k" "v")
                , test "insert" <| \() -> Expect.equal (Dict.fromList [ ( "k", "v" ) ]) (Dict.insert "k" "v" Dict.empty)
                , test "insert replace" <| \() -> Expect.equal (Dict.fromList [ ( "k", "vv" ) ]) (Dict.insert "k" "vv" (Dict.singleton "k" "v"))
                , test "update" <| \() -> Expect.equal (Dict.fromList [ ( "k", "vv" ) ]) (Dict.update "k" (\v -> Just "vv") (Dict.singleton "k" "v"))
                , test "update Nothing" <| \() -> Expect.equal Dict.empty (Dict.update "k" (\v -> Nothing) (Dict.singleton "k" "v"))
                , test "remove" <| \() -> Expect.equal Dict.empty (Dict.remove "k" (Dict.singleton "k" "v"))
                , test "remove not found" <| \() -> Expect.equal (Dict.singleton "k" "v") (Dict.remove "kk" (Dict.singleton "k" "v"))
                ]

        queryTests =
            describe "query Tests"
                [ test "member 1" <| \() -> Expect.equal True (Dict.member "Tom" animals)
                , test "member 2" <| \() -> Expect.equal False (Dict.member "Spike" animals)
                , test "get 1" <| \() -> Expect.equal (Just "cat") (Dict.get "Tom" animals)
                , test "get 2" <| \() -> Expect.equal Nothing (Dict.get "Spike" animals)
                , test "size of empty dictionary" <| \() -> Expect.equal 0 (Dict.size Dict.empty)
                , test "size of example dictionary" <| \() -> Expect.equal 2 (Dict.size animals)
                ]

        combineTests =
            describe "combine Tests"
                [ test "union" <| \() -> Expect.equal animals (Dict.union (Dict.singleton "Jerry" "mouse") (Dict.singleton "Tom" "cat"))
                , test "union collison" <| \() -> Expect.equal (Dict.singleton "Tom" "cat") (Dict.union (Dict.singleton "Tom" "cat") (Dict.singleton "Tom" "mouse"))
                , test "intersect" <| \() -> Expect.equal (Dict.singleton "Tom" "cat") (Dict.intersect animals (Dict.singleton "Tom" "cat"))
                , test "diff" <| \() -> Expect.equal (Dict.singleton "Jerry" "mouse") (Dict.diff animals (Dict.singleton "Tom" "cat"))
                ]

        transformTests =
            describe "transform Tests"
                [ test "filter" <| \() -> Expect.equal (Dict.singleton "Tom" "cat") (Dict.filter (\k v -> k == "Tom") animals)
                , test "partition" <| \() -> Expect.equal ( Dict.singleton "Tom" "cat", Dict.singleton "Jerry" "mouse" ) (Dict.partition (\k v -> k == "Tom") animals)
                ]

        mergeTests =
            let
                insertBoth key leftVal rightVal dict =
                    Dict.insert key (leftVal ++ rightVal) dict

                s1 =
                    Dict.empty |> Dict.insert "u1" [ 1 ]

                s2 =
                    Dict.empty |> Dict.insert "u2" [ 2 ]

                s23 =
                    Dict.empty |> Dict.insert "u2" [ 3 ]

                b1 =
                    List.map (\i -> ( i, [ i ] )) (List.range 1 10) |> Dict.fromList

                b2 =
                    List.map (\i -> ( i, [ i ] )) (List.range 5 15) |> Dict.fromList

                bExpected =
                    [ ( 1, [ 1 ] ), ( 2, [ 2 ] ), ( 3, [ 3 ] ), ( 4, [ 4 ] ), ( 5, [ 5, 5 ] ), ( 6, [ 6, 6 ] ), ( 7, [ 7, 7 ] ), ( 8, [ 8, 8 ] ), ( 9, [ 9, 9 ] ), ( 10, [ 10, 10 ] ), ( 11, [ 11 ] ), ( 12, [ 12 ] ), ( 13, [ 13 ] ), ( 14, [ 14 ] ), ( 15, [ 15 ] ) ]
            in
                describe "merge Tests"
                    [ test "merge empties" <|
                        \() ->
                            Expect.equal (Dict.empty)
                                (Dict.merge Dict.insert insertBoth Dict.insert Dict.empty Dict.empty Dict.empty)
                    , test "merge singletons in order" <|
                        \() ->
                            Expect.equal [ ( "u1", [ 1 ] ), ( "u2", [ 2 ] ) ]
                                ((Dict.merge Dict.insert insertBoth Dict.insert s1 s2 Dict.empty) |> Dict.toList)
                    , test "merge singletons out of order" <|
                        \() ->
                            Expect.equal [ ( "u1", [ 1 ] ), ( "u2", [ 2 ] ) ]
                                ((Dict.merge Dict.insert insertBoth Dict.insert s2 s1 Dict.empty) |> Dict.toList)
                    , test "merge with duplicate key" <|
                        \() ->
                            Expect.equal [ ( "u2", [ 2, 3 ] ) ]
                                ((Dict.merge Dict.insert insertBoth Dict.insert s2 s23 Dict.empty) |> Dict.toList)
                    , test "partially overlapping" <|
                        \() ->
                            Expect.equal bExpected
                                ((Dict.merge Dict.insert insertBoth Dict.insert b1 b2 Dict.empty) |> Dict.toList)
                    ]

        fuzzTests =
            describe "Fuzz tests"
                [ fuzz fuzzPairs "Converting to/from list works" <|
                    \pairs ->
                        Dict.toList (Dict.fromList pairs)
                            |> Expect.equal (BaseDict.toList (BaseDict.fromList pairs))
                , fuzz2 fuzzPairs Fuzz.int "Insert works" <|
                    \pairs num ->
                        Dict.toList (Dict.insert num num (Dict.fromList pairs))
                            |> Expect.equal (BaseDict.toList (BaseDict.insert num num (BaseDict.fromList pairs)))
                , fuzz2 fuzzPairs Fuzz.int "Removal works" <|
                    \pairs num ->
                        Dict.toList (Dict.remove num (Dict.fromList pairs))
                            |> Expect.equal (BaseDict.toList (BaseDict.remove num (BaseDict.fromList pairs)))
                , fuzz2 fuzzPairs Fuzz.int "Insert maintains invariant" <|
                    \pairs num ->
                        Dict.validateInvariants (Dict.insert num num (Dict.fromList pairs))
                            |> Expect.equal ""
                , fuzz2 fuzzPairs Fuzz.int "Remove maintains invariant" <|
                    \pairs num ->
                        Dict.validateInvariants (Dict.remove num (Dict.fromList pairs))
                            |> Expect.equal ""
                ]
    in
        describe "Dict Tests"
            [ buildTests
            , queryTests
            , combineTests
            , transformTests
            , mergeTests
            , fuzzTests
            ]
