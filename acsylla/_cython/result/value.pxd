cdef class Value:
    cdef:
        const CassValue* cass_value

    @staticmethod
    cdef Value new_(CassValue* cass_value)

cdef class DataType:
    cdef:
        const CassDataType* cass_data_type

    @staticmethod
    cdef DataType new_(CassDataType* cass_data_type)
