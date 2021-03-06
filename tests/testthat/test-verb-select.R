context("select")

df <- as.data.frame(as.list(setNames(1:26, letters)))
tbls <- test_load(df)


test_that("select quotes correctly", {
  out <- memdb_frame(x = 1, y = 1) %>%
    select(x) %>%
    collect()
  expect_equal(out, tibble(x = 1))
})

test_that("select can rename", {
  out <- memdb_frame(x = 1, y = 2) %>%
    select(y = x) %>%
    collect()
  expect_equal(out, tibble(y = 1))
})

test_that("two selects equivalent to one", {
  mf <- memdb_frame(a = 1, b = 1, c = 1, d = 2)

  out <- mf %>%
    select(a:c) %>%
    select(b:c) %>%
    collect()

  expect_named(out, c("b", "c"))
})

test_that("select operates on mutated vars", {
  mf <- memdb_frame(x = c(1, 2, 3), y = c(3, 2, 1))

  df1 <- mf %>%
    mutate(x, z = x + y) %>%
    select(z) %>%
    collect()

  df2 <- mf %>%
    collect() %>%
    mutate(x, z = x + y) %>%
    select(z)

  expect_equal_tbl(df1, df2)
})

test_that("select renames variables (#317)", {
  mf <- memdb_frame(x = 1, y = 2)
  expect_equal_tbl(mf %>% select(A = x), tibble(A = 1))
})

test_that("rename renames variables", {
  mf <- memdb_frame(x = 1, y = 2)
  expect_equal_tbl(mf %>% rename(A = x), tibble(A = 1, y = 2))
})

test_that("can rename multiple vars", {
  mf <- memdb_frame(a = 1, b = 2)
  exp <- tibble(c = 1, d = 2)

  expect_equal_tbl(mf %>% rename(c = a, d = b), exp)
  expect_equal_tbl(mf %>% group_by(a) %>% rename(c = a, d = b), exp)
})

test_that("select preserves grouping vars", {
  mf <- memdb_frame(a = 1, b = 2) %>% group_by(b)
  out <- mf %>% select(a) %>% collect()

  expect_named(out, c("b", "a"))
})


# sql_build -------------------------------------------------------------

test_that("select picks variables", {
  out <- lazy_frame(x1 = 1, x2 = 1, x3 = 2) %>%
    select(x1:x2) %>%
    sql_build()

  expect_equal(out$select, ident("x1" = "x1", "x2" = "x2"))
})

test_that("select renames variables", {
  out <- lazy_frame(x1 = 1, x2 = 1, x3 = 2) %>%
    select(y = x1, z = x2) %>%
    sql_build()

  expect_equal(out$select, ident("y" = "x1", "z" = "x2"))
})

test_that("select can refer to variables in local env", {
  vars <- c("x", "y")
  out <- lazy_frame(x = 1, y = 1) %>%
    select(one_of(vars)) %>%
    sql_build()

  expect_equal(out$select, ident("x" = "x", "y" = "y"))
})

test_that("rename preserves existing vars", {
  out <- lazy_frame(x = 1, y = 1) %>%
    rename(z = y) %>%
    sql_build()

  expect_equal(out$select, ident("x" = "x", "z" = "y"))
})

