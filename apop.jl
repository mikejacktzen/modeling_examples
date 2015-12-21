# require("GSL")
using(GSL)

# WARNING: Base.Uint8 is deprecated, use UInt8 instead.
# WARNING: Base.String is deprecated, use AbstractString instead.

type apop_name
    title::Ptr{UInt8}
    vector::Ptr{UInt8}
    col::Ptr{Ptr{UInt8}}
    row::Ptr{Ptr{UInt8}}
    text::Ptr{Ptr{UInt8}}
    colct::Int32
    rowct::Int32
    textct::Int32
end

type apop_data
    vector::Ptr{gsl_vector}  
    matrix::Ptr{gsl_matrix}
    names::Ptr{apop_name}
    text::Ptr{Ptr{Ptr{UInt8}}}
    textsize1::Int32
    textsize2::Int32
    weights::Ptr{gsl_vector}
    more::Ptr{apop_data}
    error::UInt8
end

bitstype 101*8 backbeat

type apop_model
    name::backbeat
    vsize::Int32
    msize1::Int32
    msize2::Int32
    dsize::Int32
    #apop_settings_type *settings;
    data::Ptr{apop_data}
    parameters::Ptr{apop_data}
    info::Ptr{apop_data}
    #    void (*estimate)(apop_data * data, apop_model *params);
    estimate::Ptr{Void}
    #long double (*p)(apop_data *d, apop_model *params);
    p::Ptr{Void}
    #long double (*log_likelihood)(apop_data *d, apop_model *params);
    log_likelihood::Ptr{Void}
    #long double (*cdf)(apop_data *d, apop_model *params);
    cdf::Ptr{Void}
    #    long double (*constraint)(apop_data *data, apop_model *params);
    constraint::Ptr{Void}
    #    void (*draw)(double *out, gsl_rng* r, apop_model *params);
    draw::Ptr{Void}
    #    void (*prep)(apop_data *data, apop_model *params);
    prep::Ptr{Void}
    #    void (*print)(apop_model *params, FILE *out);
    settings::Ptr{Void}
    more::Ptr{Void}
    more_size::Int32
    error::UInt8
end

# WARNING: Base.String is deprecated, use AbstractString instead.

function db_open(dbname::AbstractString)
  val = ccall( (:apop_db_open, "libapophenia"),
              Int32, (Ptr{UInt8},), bytestring(dbname))
  if val == 1
    error("db_open: failed to open", dbname)
  end
  val
end

function db_close()
  val = ccall( (:apop_db_close_base, "libapophenia"),
              Int32, (UInt8,), 'q')
  if val != 0
    error("db_close failed to close database")
  end
  val
end

function text_to_db(filename::AbstractString, tabname::AbstractString)
    out = ccall( (:apop_text_to_db_base, "libapophenia"),
        Cint,
        (Ptr{UInt8},Ptr{UInt8}, Int32, Int32, Ptr{Ptr{UInt8}},
        Ptr{UInt8},Ptr{apop_data}, Ptr{UInt8}, Ptr{UInt8}),
        bytestring(filename), 
        bytestring(tabname), 
        'n', 'y', C_NULL, C_NULL, C_NULL, C_NULL, bytestring("|\t ")
     )
  if out == 1
    error("text_to_db: trouble reading", filename)
  end
  out
end

function query_to_data(query::AbstractString)
    out = ccall( (:apop_query_to_data, "libapophenia"),
              Ptr{apop_data}, (Ptr{UInt8},), bytestring(query)) 
    data = unsafe_load(out)
    if data.error != 0
        error("query_to_data: trouble with query:", query)
    end
    out
end

#Just the vector. No names.
function data_as_vector(inptr::Ptr{apop_data})
    in = unsafe_load(inptr)
    if in.vector == C_NULL
        return ()
    end
    m = unsafe_load(in.vector)
    transpose(pointer_to_array(m.data, (int(m.size),)))
end
    
#Just the matrix. No names.
# WARNING: int(x) is deprecated, use Int(x) instead.

function data_as_array(inptr::Ptr{apop_data})
    in = unsafe_load(inptr)
    if in.matrix == C_NULL
        return ()
    end
    m = unsafe_load(in.matrix)
    transpose(pointer_to_array(m.data, (Int(m.size2), Int(m.size1))))
end

function apop_estimate(data::Ptr{apop_data}, mstring::AbstractString)
    mptr = @eval cglobal( ($(mstring), "libapophenia"), Ptr{apop_model})
    out = ccall((:apop_estimate, "libapophenia"),
            Ptr{apop_model},
            (Ptr{apop_data}, Ptr{apop_model}),
            data, unsafe_load(mptr))
    unsafe_load(out)        
end
