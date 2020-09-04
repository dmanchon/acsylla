cdef class Result:

    def __cinit__(self):
        self.cass_result = NULL

    def __dealloc__(self):
        cass_result_free(self.cass_result)

    @staticmethod
    cdef Result new_(const CassResult* cass_result):
        cdef Result result

        result = Result()
        result.cass_result = cass_result
        return result

    def has_more_pages(self):
        """ Returns true if there is still pages to be fetched"""
        cdef cass_bool_t more_pages

        more_pages = cass_result_has_more_pages(self.cass_result)
        if more_pages == cass_true:
            return True
        else:
            return False

    def page_state(self):
        """ Returns a token with the page state for continuing fetching
        new results.

        First checks if there are more results using the `has_more_pages` function,
        and if there are use this token as an argument of the factories for creating
        an statement.
        """
        cdef Py_ssize_t length = 0
        cdef char* output = NULL
        cdef CassError error
        cdef bytes page_state

        error = cass_result_paging_state_token(self.cass_result, <const char**> &output, <size_t*> &length)
        if error != CASS_OK:
            raise RuntimeError("Error {} trying to get the page token state".format(error))

        # This pointer does not need to be free up since its an
        # slice of the buffer kept by the Cassandra driver and related to
        # the result. When the result is free up all the space will be free up.
        page_state = output[:length]
        return page_state

    def count(self):
        """ Returns the total rows of the result"""
        cdef size_t count

        count = cass_result_row_count(self.cass_result)
        return count

    def column_type(self, str name):
        cdef size_t index
        column = None
        cdef size_t len
        cdef const char* string

        for i in range(self.column_count()):
            cass_result_column_name(self.cass_result, i, &string, &len)
            if string == name:
                column = cass_result_column_type(self.cass_result, i)
                break
        return column

    def column_count(self):
        """ Returns the total columns returned"""
        cdef size_t count

        count = cass_result_column_count(self.cass_result)
        return count

    def first(self):
        """ Return the first result, if there is no row
        returns None.
        """
        cdef const CassRow* cass_row

        cass_row = cass_result_first_row(self.cass_result)
        if (cass_row == NULL):
            return None

        return Row.new_(cass_row, self)

    def all(self):
        """ Return the all rows using of a result, using an
        iterator.

        If there is no rows iterator returns no rows.
        """
        cdef CassIterator* cass_iterator
        cdef const CassRow* cass_row

        try:
            cass_iterator = cass_iterator_from_result(self.cass_result)
            while (cass_iterator_next(cass_iterator) == cass_true):
                cass_row = cass_iterator_get_row(cass_iterator)
                yield Row.new_(cass_row, self)
        finally:
            cass_iterator_free(cass_iterator)
