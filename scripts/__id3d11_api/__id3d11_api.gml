// ##### extgen :: Auto-generated file do not edit!! #####

// #####################################################################
// # Macros
// #####################################################################

// #####################################################################
// # Enums
// #####################################################################

enum ID3D11HandleKind
{
    Invalid = 0,
    Device = 1,
    DeviceContext = 2,
    SwapChain = 3,
    Buffer = 4,
    Texture1D = 5,
    Texture2D = 6,
    Texture3D = 7,
    Shader = 8,
    View = 9,
    State = 10,
    Query = 11,
    CommandList = 12,
    Fence = 13,
    Device1 = 14,
    Device2 = 15,
    Device3 = 16,
    Device4 = 17,
    Device5 = 18,
    DeviceContext1 = 19,
    DeviceContext2 = 20,
    DeviceContext3 = 21,
    DeviceContext4 = 22,
    Multithread = 23,
    DeviceChild = 24,
    Resource = 25,
    Texture2D1 = 26,
    Texture3D1 = 27,
    ShaderResourceView = 28,
    ShaderResourceView1 = 29,
    RenderTargetView = 30,
    RenderTargetView1 = 31,
    DepthStencilView = 32,
    UnorderedAccessView = 33,
    UnorderedAccessView1 = 34,
    VertexShader = 35,
    HullShader = 36,
    DomainShader = 37,
    GeometryShader = 38,
    PixelShader = 39,
    ComputeShader = 40,
    InputLayout = 41,
    SamplerState = 42,
    DepthStencilState = 43,
    BlendState = 44,
    BlendState1 = 45,
    RasterizerState = 46,
    RasterizerState1 = 47,
    RasterizerState2 = 48,
    Asynchronous = 49,
    Predicate = 50,
    Counter = 51,
    Query1 = 52,
    ClassInstance = 53,
    ClassLinkage = 54,
    VideoDecoder = 55,
    VideoProcessorEnumerator = 56,
    VideoProcessorEnumerator1 = 57,
    VideoProcessor = 58,
    AuthenticatedChannel = 59,
    CryptoSession = 60,
    VideoDecoderOutputView = 61,
    VideoProcessorInputView = 62,
    VideoProcessorOutputView = 63,
    VideoContext = 64,
    VideoContext1 = 65,
    VideoContext2 = 66,
    VideoContext3 = 67,
    VideoDevice = 68,
    VideoDevice1 = 69,
    VideoDevice2 = 70
}

enum ID3D11FeatureLevel
{
    Level9_1 = 37120,
    Level9_2 = 37376,
    Level9_3 = 37632,
    Level10_0 = 40960,
    Level10_1 = 41216,
    Level11_0 = 45056,
    Level11_1 = 45312,
    Level12_0 = 49152,
    Level12_1 = 49408,
    Level12_2 = 49664
}

enum ID3D11Usage
{
    Default = 0,
    Immutable = 1,
    Dynamic = 2,
    Staging = 3
}

enum ID3D11BindFlag
{
    VertexBuffer = 1,
    IndexBuffer = 2,
    ConstantBuffer = 4,
    ShaderResource = 8,
    StreamOutput = 16,
    RenderTarget = 32,
    DepthStencil = 64,
    UnorderedAccess = 128,
    Decoder = 512,
    VideoEncoder = 1024
}

enum ID3D11CpuAccessFlag
{
    Write = 65536,
    Read = 131072
}

enum ID3D11ResourceMiscFlag
{
    GenerateMips = 1,
    Shared = 2,
    TextureCube = 4,
    DrawIndirectArgs = 16,
    BufferAllowRawViews = 32,
    BufferStructured = 64,
    ResourceClamp = 128,
    SharedKeyedMutex = 256,
    GdiCompatible = 512,
    SharedNtHandle = 2048,
    RestrictedContent = 4096,
    RestrictSharedResource = 8192,
    RestrictSharedResourceDriver = 16384,
    Guarded = 32768,
    TilePool = 131072,
    Tiled = 262144,
    HardwareProtected = 524288,
    SharedDisplayable = 1048576,
    SharedExclusiveWriter = 2097152,
    NoShaderAccess = 4194304
}

enum ID3D11BufferUavFlag
{
    Raw = 1,
    Append = 2,
    Counter = 4
}

enum ID3D11ClearFlag
{
    Depth = 1,
    Stencil = 2
}

enum ID3D11ResourceDimension
{
    Unknown = 0,
    Buffer = 1,
    Texture1D = 2,
    Texture2D = 3,
    Texture3D = 4
}

enum ID3D11ShaderResourceViewDimension
{
    Unknown = 0,
    Buffer = 1,
    Texture1D = 2,
    Texture1DArray = 3,
    Texture2D = 4,
    Texture2DArray = 5,
    Texture2DMS = 6,
    Texture2DMSArray = 7,
    Texture3D = 8,
    TextureCube = 9,
    TextureCubeArray = 10,
    BufferEx = 11
}

enum ID3D11RenderTargetViewDimension
{
    Unknown = 0,
    Buffer = 1,
    Texture1D = 2,
    Texture1DArray = 3,
    Texture2D = 4,
    Texture2DArray = 5,
    Texture2DMS = 6,
    Texture2DMSArray = 7,
    Texture3D = 8
}

enum ID3D11DepthStencilViewDimension
{
    Unknown = 0,
    Texture1D = 1,
    Texture1DArray = 2,
    Texture2D = 3,
    Texture2DArray = 4,
    Texture2DMS = 5,
    Texture2DMSArray = 6
}

enum ID3D11UnorderedAccessViewDimension
{
    Unknown = 0,
    Buffer = 1,
    Texture1D = 2,
    Texture1DArray = 3,
    Texture2D = 4,
    Texture2DArray = 5,
    Texture3D = 8
}

enum ID3D11InputClassification
{
    PerVertexData = 0,
    PerInstanceData = 1
}

enum ID3D11Filter
{
    MinMagMipPoint = 0,
    MinMagPointMipLinear = 1,
    MinPointMagLinearMipPoint = 4,
    MinPointMagMipLinear = 5,
    MinLinearMagMipPoint = 16,
    MinLinearMagPointMipLinear = 17,
    MinMagLinearMipPoint = 20,
    MinMagMipLinear = 21,
    Anisotropic = 85,
    ComparisonMinMagMipPoint = 128,
    ComparisonMinMagPointMipLinear = 129,
    ComparisonMinPointMagLinearMipPoint = 132,
    ComparisonMinPointMagMipLinear = 133,
    ComparisonMinLinearMagMipPoint = 144,
    ComparisonMinLinearMagPointMipLinear = 145,
    ComparisonMinMagLinearMipPoint = 148,
    ComparisonMinMagMipLinear = 149,
    ComparisonAnisotropic = 213,
    MinimumMinMagMipPoint = 256,
    MinimumMinMagPointMipLinear = 257,
    MinimumMinPointMagLinearMipPoint = 260,
    MinimumMinPointMagMipLinear = 261,
    MinimumMinLinearMagMipPoint = 272,
    MinimumMinLinearMagPointMipLinear = 273,
    MinimumMinMagLinearMipPoint = 276,
    MinimumMinMagMipLinear = 277,
    MinimumAnisotropic = 341,
    MaximumMinMagMipPoint = 384,
    MaximumMinMagPointMipLinear = 385,
    MaximumMinPointMagLinearMipPoint = 388,
    MaximumMinPointMagMipLinear = 389,
    MaximumMinLinearMagMipPoint = 400,
    MaximumMinLinearMagPointMipLinear = 401,
    MaximumMinMagLinearMipPoint = 404,
    MaximumMinMagMipLinear = 405,
    MaximumAnisotropic = 469
}

enum ID3D11TextureAddressMode
{
    Wrap = 1,
    Mirror = 2,
    Clamp = 3,
    Border = 4,
    MirrorOnce = 5
}

enum ID3D11ComparisonFunc
{
    Never = 1,
    Less = 2,
    Equal = 3,
    LessEqual = 4,
    Greater = 5,
    NotEqual = 6,
    GreaterEqual = 7,
    Always = 8
}

enum ID3D11FillMode
{
    Wireframe = 2,
    Solid = 3
}

enum ID3D11CullMode
{
    None = 1,
    Front = 2,
    Back = 3
}

enum ID3D11Blend
{
    Zero = 1,
    One = 2,
    SrcColor = 3,
    InvSrcColor = 4,
    SrcAlpha = 5,
    InvSrcAlpha = 6,
    DestAlpha = 7,
    InvDestAlpha = 8,
    DestColor = 9,
    InvDestColor = 10,
    SrcAlphaSat = 11,
    BlendFactor = 14,
    InvBlendFactor = 15,
    Src1Color = 16,
    InvSrc1Color = 17,
    Src1Alpha = 18,
    InvSrc1Alpha = 19
}

enum ID3D11BlendOp
{
    Add = 1,
    Subtract = 2,
    RevSubtract = 3,
    Min = 4,
    Max = 5
}

enum ID3D11ColorWriteEnable
{
    Red = 1,
    Green = 2,
    Blue = 4,
    Alpha = 8,
    All = 15
}

enum ID3D11DepthWriteMask
{
    Zero = 0,
    All = 1
}

enum ID3D11StencilOp
{
    Keep = 1,
    Zero = 2,
    Replace = 3,
    IncrSat = 4,
    DecrSat = 5,
    Invert = 6,
    Incr = 7,
    Decr = 8
}

enum ID3D11Query
{
    Event = 0,
    Occlusion = 1,
    Timestamp = 2,
    TimestampDisjoint = 3,
    PipelineStatistics = 4,
    OcclusionPredicate = 5,
    StreamOutputStatistics = 6,
    StreamOutputOverflowPredicate = 7,
    StreamOutputStatisticsStream0 = 8,
    StreamOutputOverflowPredicateStream0 = 9,
    StreamOutputStatisticsStream1 = 10,
    StreamOutputOverflowPredicateStream1 = 11,
    StreamOutputStatisticsStream2 = 12,
    StreamOutputOverflowPredicateStream2 = 13,
    StreamOutputStatisticsStream3 = 14,
    StreamOutputOverflowPredicateStream3 = 15
}

enum ID3D11QueryMiscFlag
{
    PredicateHint = 1
}

enum ID3D11AsyncGetDataFlag
{
    DoNotFlush = 1
}

enum ID3D11Counter
{
    DeviceDependent0 = 1073741824
}

enum ID3D11CounterType
{
    Float32 = 0,
    Uint16 = 1,
    Uint32 = 2,
    Uint64 = 3
}

enum ID3D11PrimitiveTopology
{
    Undefined = 0,
    PointList = 1,
    LineList = 2,
    LineStrip = 3,
    TriangleList = 4,
    TriangleStrip = 5,
    LineListAdjacency = 10,
    LineStripAdjacency = 11,
    TriangleListAdjacency = 12,
    TriangleStripAdjacency = 13,
    PatchList1 = 33,
    PatchList2 = 34,
    PatchList3 = 35,
    PatchList4 = 36,
    PatchList5 = 37,
    PatchList6 = 38,
    PatchList7 = 39,
    PatchList8 = 40,
    PatchList9 = 41,
    PatchList10 = 42,
    PatchList11 = 43,
    PatchList12 = 44,
    PatchList13 = 45,
    PatchList14 = 46,
    PatchList15 = 47,
    PatchList16 = 48,
    PatchList17 = 49,
    PatchList18 = 50,
    PatchList19 = 51,
    PatchList20 = 52,
    PatchList21 = 53,
    PatchList22 = 54,
    PatchList23 = 55,
    PatchList24 = 56,
    PatchList25 = 57,
    PatchList26 = 58,
    PatchList27 = 59,
    PatchList28 = 60,
    PatchList29 = 61,
    PatchList30 = 62,
    PatchList31 = 63,
    PatchList32 = 64
}

// #####################################################################
// # Constructors
// #####################################################################

/**
 * @returns {Struct.ID3D11Version} 
 */
function ID3D11Version() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 783007235;

    self.major = undefined;
    self.minor = undefined;
    self.patch = undefined;
    self.abi = undefined;

}

/**
 * @returns {Struct.ID3D11FormatSupportResult} 
 */
function ID3D11FormatSupportResult() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1468699844;

    self.hresult = undefined;
    self.support = undefined;

}

/**
 * @returns {Struct.ID3D11MultisampleQualityResult} 
 */
function ID3D11MultisampleQualityResult() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 2331838588;

    self.hresult = undefined;
    self.qualityLevels = undefined;

}

/**
 * @returns {Struct.ID3D11CounterInfo} 
 */
function ID3D11CounterInfo() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 3264074355;

    self.lastDeviceDependentCounter = undefined;
    self.numSimultaneousCounters = undefined;
    self.numDetectableParallelUnits = undefined;

}

/**
 * @returns {Struct.ID3D11BufferDesc} 
 */
function ID3D11BufferDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 3031618682;

    self.byteWidth = 0;
    self.usage = 0;
    self.bindFlags = 0;
    self.cpuAccessFlags = 0;
    self.miscFlags = 0;
    self.structureByteStride = 0;

}

/**
 * @returns {Struct.ID3D11SubresourceData} 
 */
function ID3D11SubresourceData() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 351177001;

    self.offset = 0;
    self.rowPitch = 0;
    self.slicePitch = 0;
    self.dataSize = 0;

}

/**
 * @returns {Struct.ID3D11Texture1DDesc} 
 */
function ID3D11Texture1DDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1346893864;

    self.width = 0;
    self.mipLevels = 0;
    self.arraySize = 0;
    self.format = 0;
    self.usage = 0;
    self.bindFlags = 0;
    self.cpuAccessFlags = 0;
    self.miscFlags = 0;

}

/**
 * @returns {Struct.ID3D11Texture2DDesc} 
 */
function ID3D11Texture2DDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 712135135;

    self.width = 0;
    self.height = 0;
    self.mipLevels = 0;
    self.arraySize = 0;
    self.format = 0;
    self.sampleCount = 0;
    self.sampleQuality = 0;
    self.usage = 0;
    self.bindFlags = 0;
    self.cpuAccessFlags = 0;
    self.miscFlags = 0;

}

/**
 * @returns {Struct.ID3D11Texture3DDesc} 
 */
function ID3D11Texture3DDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 695491914;

    self.width = 0;
    self.height = 0;
    self.depth = 0;
    self.mipLevels = 0;
    self.format = 0;
    self.usage = 0;
    self.bindFlags = 0;
    self.cpuAccessFlags = 0;
    self.miscFlags = 0;

}

/**
 * @returns {Struct.ID3D11ShaderResourceViewDesc} 
 */
function ID3D11ShaderResourceViewDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 2369398716;

    self.format = 0;
    self.viewDimension = 0;
    self.firstElement = 0;
    self.numElements = 0;
    self.flags = 0;
    self.mostDetailedMip = 0;
    self.mipLevels = 0;
    self.firstArraySlice = 0;
    self.arraySize = 0;
    self.first2DArrayFace = 0;
    self.numCubes = 0;

}

/**
 * @returns {Struct.ID3D11RenderTargetViewDesc} 
 */
function ID3D11RenderTargetViewDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 3224692808;

    self.format = 0;
    self.viewDimension = 0;
    self.firstElement = 0;
    self.numElements = 0;
    self.mipSlice = 0;
    self.firstArraySlice = 0;
    self.arraySize = 0;
    self.firstWSlice = 0;
    self.wSize = 0;

}

/**
 * @returns {Struct.ID3D11DepthStencilViewDesc} 
 */
function ID3D11DepthStencilViewDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 2918764966;

    self.format = 0;
    self.viewDimension = 0;
    self.flags = 0;
    self.mipSlice = 0;
    self.firstArraySlice = 0;
    self.arraySize = 0;

}

/**
 * @returns {Struct.ID3D11UnorderedAccessViewDesc} 
 */
function ID3D11UnorderedAccessViewDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 783930313;

    self.format = 0;
    self.viewDimension = 0;
    self.firstElement = 0;
    self.numElements = 0;
    self.flags = 0;
    self.mipSlice = 0;
    self.firstArraySlice = 0;
    self.arraySize = 0;
    self.firstWSlice = 0;
    self.wSize = 0;

}

/**
 * @returns {Struct.ID3D11InputElementDesc} 
 */
function ID3D11InputElementDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 3369076812;

    self.semanticName = "";
    self.semanticIndex = 0;
    self.format = 0;
    self.inputSlot = 0;
    self.alignedByteOffset = 0;
    self.inputSlotClass = 0;
    self.instanceDataStepRate = 0;

}

/**
 * @returns {Struct.ID3D11StreamOutputDeclarationEntry} 
 */
function ID3D11StreamOutputDeclarationEntry() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 4192113024;

    self.semanticName = "";
    self.stream = 0;
    self.semanticIndex = 0;
    self.startComponent = 0;
    self.componentCount = 0;
    self.outputSlot = 0;

}

/**
 * @returns {Struct.ID3D11ShaderCompileResult} 
 */
function ID3D11ShaderCompileResult() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1457177816;

    self.hresult = undefined;
    self.bytecodeSize = undefined;
    self.errorSize = undefined;

}

/**
 * @returns {Struct.ID3D11SamplerDesc} 
 */
function ID3D11SamplerDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 213418622;

    self.filter = 0;
    self.addressU = 0;
    self.addressV = 0;
    self.addressW = 0;
    self.mipLodBias = 0;
    self.maxAnisotropy = 0;
    self.comparisonFunc = 0;
    self.borderColorR = 0;
    self.borderColorG = 0;
    self.borderColorB = 0;
    self.borderColorA = 0;
    self.minLod = 0;
    self.maxLod = 0;

}

/**
 * @returns {Struct.ID3D11RasterizerDesc} 
 */
function ID3D11RasterizerDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1976543893;

    self.fillMode = 0;
    self.cullMode = 0;
    self.frontCounterClockwise = false;
    self.depthBias = 0;
    self.depthBiasClamp = 0;
    self.slopeScaledDepthBias = 0;
    self.depthClipEnable = false;
    self.scissorEnable = false;
    self.multisampleEnable = false;
    self.antialiasedLineEnable = false;

}

/**
 * @returns {Struct.ID3D11RenderTargetBlendDesc} 
 */
function ID3D11RenderTargetBlendDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 2265759682;

    self.blendEnable = false;
    self.srcBlend = 0;
    self.destBlend = 0;
    self.blendOp = 0;
    self.srcBlendAlpha = 0;
    self.destBlendAlpha = 0;
    self.blendOpAlpha = 0;
    self.renderTargetWriteMask = 0;

}

/**
 * @returns {Struct.ID3D11DepthStencilOpDesc} 
 */
function ID3D11DepthStencilOpDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1005052320;

    self.stencilFailOp = 0;
    self.stencilDepthFailOp = 0;
    self.stencilPassOp = 0;
    self.stencilFunc = 0;

}

/**
 * @returns {Struct.ID3D11QueryDesc} 
 */
function ID3D11QueryDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 3852865306;

    self.query = 0;
    self.miscFlags = 0;

}

/**
 * @returns {Struct.ID3D11CounterDesc} 
 */
function ID3D11CounterDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 663643394;

    self.counter = 0;
    self.miscFlags = 0;

}

/**
 * @returns {Struct.ID3D11CheckCounterResult} 
 */
function ID3D11CheckCounterResult() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 3339861500;

    self.hresult = undefined;
    self.type = undefined;
    self.activeCounters = undefined;
    self.name = undefined;
    self.units = undefined;
    self.description = undefined;

}

/**
 * @returns {Struct.ID3D11BlendStateBinding} 
 */
function ID3D11BlendStateBinding() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 3920622542;

    self.state = undefined;
    self.blendFactor = undefined;
    self.sampleMask = undefined;

}

/**
 * @returns {Struct.ID3D11DepthStencilStateBinding} 
 */
function ID3D11DepthStencilStateBinding() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1872936872;

    self.state = undefined;
    self.stencilRef = undefined;

}

/**
 * @returns {Struct.ID3D11PredicationBinding} 
 */
function ID3D11PredicationBinding() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 367681888;

    self.predicate = undefined;
    self.predicateValue = undefined;

}

/**
 * @returns {Struct.ID3D11VertexBufferBinding} 
 */
function ID3D11VertexBufferBinding() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 2088290246;

    self.buffer = 0;
    self.stride = 0;
    self.offset = 0;

}

/**
 * @returns {Struct.ID3D11IndexBufferBinding} 
 */
function ID3D11IndexBufferBinding() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 4204106626;

    self.buffer = 0;
    self.format = 0;
    self.offset = 0;

}

/**
 * @returns {Struct.ID3D11Viewport} 
 */
function ID3D11Viewport() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 689095599;

    self.topLeftX = 0;
    self.topLeftY = 0;
    self.width = 0;
    self.height = 0;
    self.minDepth = 0;
    self.maxDepth = 0;

}

/**
 * @returns {Struct.ID3D11Rect} 
 */
function ID3D11Rect() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 2780430747;

    self.left = 0;
    self.top = 0;
    self.right = 0;
    self.bottom = 0;

}

/**
 * @returns {Struct.ID3D11Box} 
 */
function ID3D11Box() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 2185347734;

    self.left = undefined;
    self.top = undefined;
    self.front = undefined;
    self.right = undefined;
    self.bottom = undefined;
    self.back = undefined;

}

/**
 * @returns {Struct.ID3D11ShaderBinding} 
 */
function ID3D11ShaderBinding() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 944748101;

    self.shader = undefined;
    self.classInstances = undefined;

}

/**
 * @returns {Struct.ID3D11ClassInstanceDesc} 
 */
function ID3D11ClassInstanceDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1818198161;

    self.instanceId = undefined;
    self.instanceIndex = undefined;
    self.typeId = undefined;
    self.constantBuffer = undefined;
    self.baseConstantBufferOffset = undefined;
    self.baseTexture = undefined;
    self.baseSampler = undefined;
    self.created = undefined;

}

/**
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function ID3D11CreateHandleResult() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1461970302;

    self.hresult = undefined;
    self.handle = undefined;

}

/**
 * @returns {Struct.ID3D11BlendDesc} 
 */
function ID3D11BlendDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 728541829;

    self.alphaToCoverageEnable = false;
    self.independentBlendEnable = false;
    self.renderTargets = [];

}

/**
 * @returns {Struct.ID3D11DepthStencilDesc} 
 */
function ID3D11DepthStencilDesc() constructor
{
    /**
     * Internally generated hash for quick validation
     * @ignore 
     */
    static __uid = 1807275747;

    self.depthEnable = false;
    self.depthWriteMask = 0;
    self.depthFunc = 0;
    self.stencilEnable = false;
    self.stencilReadMask = 0;
    self.stencilWriteMask = 0;
    self.frontFace = new ID3D11DepthStencilOpDesc();
    self.backFace = new ID3D11DepthStencilOpDesc();

}

// #####################################################################
// # Codecs
// #####################################################################

/**
 * @func __ID3D11Version_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11Version} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11Version_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: major, type: UInt32
        if (!is_numeric(self.major)) show_error($"{_where} :: self.major expected number", true);
        buffer_write(_buffer, buffer_u32, self.major);

        // field: minor, type: UInt32
        if (!is_numeric(self.minor)) show_error($"{_where} :: self.minor expected number", true);
        buffer_write(_buffer, buffer_u32, self.minor);

        // field: patch, type: UInt32
        if (!is_numeric(self.patch)) show_error($"{_where} :: self.patch expected number", true);
        buffer_write(_buffer, buffer_u32, self.patch);

        // field: abi, type: UInt32
        if (!is_numeric(self.abi)) show_error($"{_where} :: self.abi expected number", true);
        buffer_write(_buffer, buffer_u32, self.abi);

    }
}

/**
 * @func __ID3D11Version_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11Version} 
 * @ignore 
 */
function __ID3D11Version_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11Version();
    with (_inst)
    {
        // field: major, type: UInt32
        self.major = buffer_read(_buffer, buffer_u32);

        // field: minor, type: UInt32
        self.minor = buffer_read(_buffer, buffer_u32);

        // field: patch, type: UInt32
        self.patch = buffer_read(_buffer, buffer_u32);

        // field: abi, type: UInt32
        self.abi = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11FormatSupportResult_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11FormatSupportResult} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11FormatSupportResult_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: hresult, type: Int32
        if (!is_numeric(self.hresult)) show_error($"{_where} :: self.hresult expected number", true);
        buffer_write(_buffer, buffer_s32, self.hresult);

        // field: support, type: UInt32
        if (!is_numeric(self.support)) show_error($"{_where} :: self.support expected number", true);
        buffer_write(_buffer, buffer_u32, self.support);

    }
}

/**
 * @func __ID3D11FormatSupportResult_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11FormatSupportResult} 
 * @ignore 
 */
function __ID3D11FormatSupportResult_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11FormatSupportResult();
    with (_inst)
    {
        // field: hresult, type: Int32
        self.hresult = buffer_read(_buffer, buffer_s32);

        // field: support, type: UInt32
        self.support = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11MultisampleQualityResult_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11MultisampleQualityResult} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11MultisampleQualityResult_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: hresult, type: Int32
        if (!is_numeric(self.hresult)) show_error($"{_where} :: self.hresult expected number", true);
        buffer_write(_buffer, buffer_s32, self.hresult);

        // field: qualityLevels, type: UInt32
        if (!is_numeric(self.qualityLevels)) show_error($"{_where} :: self.qualityLevels expected number", true);
        buffer_write(_buffer, buffer_u32, self.qualityLevels);

    }
}

/**
 * @func __ID3D11MultisampleQualityResult_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11MultisampleQualityResult} 
 * @ignore 
 */
function __ID3D11MultisampleQualityResult_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11MultisampleQualityResult();
    with (_inst)
    {
        // field: hresult, type: Int32
        self.hresult = buffer_read(_buffer, buffer_s32);

        // field: qualityLevels, type: UInt32
        self.qualityLevels = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11CounterInfo_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11CounterInfo} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11CounterInfo_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: lastDeviceDependentCounter, type: UInt32
        if (!is_numeric(self.lastDeviceDependentCounter)) show_error($"{_where} :: self.lastDeviceDependentCounter expected number", true);
        buffer_write(_buffer, buffer_u32, self.lastDeviceDependentCounter);

        // field: numSimultaneousCounters, type: UInt32
        if (!is_numeric(self.numSimultaneousCounters)) show_error($"{_where} :: self.numSimultaneousCounters expected number", true);
        buffer_write(_buffer, buffer_u32, self.numSimultaneousCounters);

        // field: numDetectableParallelUnits, type: UInt32
        if (!is_numeric(self.numDetectableParallelUnits)) show_error($"{_where} :: self.numDetectableParallelUnits expected number", true);
        buffer_write(_buffer, buffer_u32, self.numDetectableParallelUnits);

    }
}

/**
 * @func __ID3D11CounterInfo_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11CounterInfo} 
 * @ignore 
 */
function __ID3D11CounterInfo_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11CounterInfo();
    with (_inst)
    {
        // field: lastDeviceDependentCounter, type: UInt32
        self.lastDeviceDependentCounter = buffer_read(_buffer, buffer_u32);

        // field: numSimultaneousCounters, type: UInt32
        self.numSimultaneousCounters = buffer_read(_buffer, buffer_u32);

        // field: numDetectableParallelUnits, type: UInt32
        self.numDetectableParallelUnits = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11BufferDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11BufferDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11BufferDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: byteWidth, type: UInt32
        if (!is_numeric(self.byteWidth)) show_error($"{_where} :: self.byteWidth expected number", true);
        buffer_write(_buffer, buffer_u32, self.byteWidth);

        // field: usage, type: UInt32
        if (!is_numeric(self.usage)) show_error($"{_where} :: self.usage expected number", true);
        buffer_write(_buffer, buffer_u32, self.usage);

        // field: bindFlags, type: UInt32
        if (!is_numeric(self.bindFlags)) show_error($"{_where} :: self.bindFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.bindFlags);

        // field: cpuAccessFlags, type: UInt32
        if (!is_numeric(self.cpuAccessFlags)) show_error($"{_where} :: self.cpuAccessFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.cpuAccessFlags);

        // field: miscFlags, type: UInt32
        if (!is_numeric(self.miscFlags)) show_error($"{_where} :: self.miscFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.miscFlags);

        // field: structureByteStride, type: UInt32
        if (!is_numeric(self.structureByteStride)) show_error($"{_where} :: self.structureByteStride expected number", true);
        buffer_write(_buffer, buffer_u32, self.structureByteStride);

    }
}

/**
 * @func __ID3D11BufferDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11BufferDesc} 
 * @ignore 
 */
function __ID3D11BufferDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11BufferDesc();
    with (_inst)
    {
        // field: byteWidth, type: UInt32
        self.byteWidth = buffer_read(_buffer, buffer_u32);

        // field: usage, type: UInt32
        self.usage = buffer_read(_buffer, buffer_u32);

        // field: bindFlags, type: UInt32
        self.bindFlags = buffer_read(_buffer, buffer_u32);

        // field: cpuAccessFlags, type: UInt32
        self.cpuAccessFlags = buffer_read(_buffer, buffer_u32);

        // field: miscFlags, type: UInt32
        self.miscFlags = buffer_read(_buffer, buffer_u32);

        // field: structureByteStride, type: UInt32
        self.structureByteStride = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11SubresourceData_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11SubresourceData} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11SubresourceData_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: offset, type: UInt64
        if (!is_numeric(self.offset)) show_error($"{_where} :: self.offset expected number", true);
        buffer_write(_buffer, buffer_u64, self.offset);

        // field: rowPitch, type: UInt32
        if (!is_numeric(self.rowPitch)) show_error($"{_where} :: self.rowPitch expected number", true);
        buffer_write(_buffer, buffer_u32, self.rowPitch);

        // field: slicePitch, type: UInt32
        if (!is_numeric(self.slicePitch)) show_error($"{_where} :: self.slicePitch expected number", true);
        buffer_write(_buffer, buffer_u32, self.slicePitch);

        // field: dataSize, type: UInt64
        if (!is_numeric(self.dataSize)) show_error($"{_where} :: self.dataSize expected number", true);
        buffer_write(_buffer, buffer_u64, self.dataSize);

    }
}

/**
 * @func __ID3D11SubresourceData_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11SubresourceData} 
 * @ignore 
 */
function __ID3D11SubresourceData_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11SubresourceData();
    with (_inst)
    {
        // field: offset, type: UInt64
        self.offset = buffer_read(_buffer, buffer_u64);

        // field: rowPitch, type: UInt32
        self.rowPitch = buffer_read(_buffer, buffer_u32);

        // field: slicePitch, type: UInt32
        self.slicePitch = buffer_read(_buffer, buffer_u32);

        // field: dataSize, type: UInt64
        self.dataSize = buffer_read(_buffer, buffer_u64);

    }

    return _inst;
}

/**
 * @func __ID3D11Texture1DDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11Texture1DDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11Texture1DDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: width, type: UInt32
        if (!is_numeric(self.width)) show_error($"{_where} :: self.width expected number", true);
        buffer_write(_buffer, buffer_u32, self.width);

        // field: mipLevels, type: UInt32
        if (!is_numeric(self.mipLevels)) show_error($"{_where} :: self.mipLevels expected number", true);
        buffer_write(_buffer, buffer_u32, self.mipLevels);

        // field: arraySize, type: UInt32
        if (!is_numeric(self.arraySize)) show_error($"{_where} :: self.arraySize expected number", true);
        buffer_write(_buffer, buffer_u32, self.arraySize);

        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: usage, type: UInt32
        if (!is_numeric(self.usage)) show_error($"{_where} :: self.usage expected number", true);
        buffer_write(_buffer, buffer_u32, self.usage);

        // field: bindFlags, type: UInt32
        if (!is_numeric(self.bindFlags)) show_error($"{_where} :: self.bindFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.bindFlags);

        // field: cpuAccessFlags, type: UInt32
        if (!is_numeric(self.cpuAccessFlags)) show_error($"{_where} :: self.cpuAccessFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.cpuAccessFlags);

        // field: miscFlags, type: UInt32
        if (!is_numeric(self.miscFlags)) show_error($"{_where} :: self.miscFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.miscFlags);

    }
}

/**
 * @func __ID3D11Texture1DDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11Texture1DDesc} 
 * @ignore 
 */
function __ID3D11Texture1DDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11Texture1DDesc();
    with (_inst)
    {
        // field: width, type: UInt32
        self.width = buffer_read(_buffer, buffer_u32);

        // field: mipLevels, type: UInt32
        self.mipLevels = buffer_read(_buffer, buffer_u32);

        // field: arraySize, type: UInt32
        self.arraySize = buffer_read(_buffer, buffer_u32);

        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: usage, type: UInt32
        self.usage = buffer_read(_buffer, buffer_u32);

        // field: bindFlags, type: UInt32
        self.bindFlags = buffer_read(_buffer, buffer_u32);

        // field: cpuAccessFlags, type: UInt32
        self.cpuAccessFlags = buffer_read(_buffer, buffer_u32);

        // field: miscFlags, type: UInt32
        self.miscFlags = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11Texture2DDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11Texture2DDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11Texture2DDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: width, type: UInt32
        if (!is_numeric(self.width)) show_error($"{_where} :: self.width expected number", true);
        buffer_write(_buffer, buffer_u32, self.width);

        // field: height, type: UInt32
        if (!is_numeric(self.height)) show_error($"{_where} :: self.height expected number", true);
        buffer_write(_buffer, buffer_u32, self.height);

        // field: mipLevels, type: UInt32
        if (!is_numeric(self.mipLevels)) show_error($"{_where} :: self.mipLevels expected number", true);
        buffer_write(_buffer, buffer_u32, self.mipLevels);

        // field: arraySize, type: UInt32
        if (!is_numeric(self.arraySize)) show_error($"{_where} :: self.arraySize expected number", true);
        buffer_write(_buffer, buffer_u32, self.arraySize);

        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: sampleCount, type: UInt32
        if (!is_numeric(self.sampleCount)) show_error($"{_where} :: self.sampleCount expected number", true);
        buffer_write(_buffer, buffer_u32, self.sampleCount);

        // field: sampleQuality, type: UInt32
        if (!is_numeric(self.sampleQuality)) show_error($"{_where} :: self.sampleQuality expected number", true);
        buffer_write(_buffer, buffer_u32, self.sampleQuality);

        // field: usage, type: UInt32
        if (!is_numeric(self.usage)) show_error($"{_where} :: self.usage expected number", true);
        buffer_write(_buffer, buffer_u32, self.usage);

        // field: bindFlags, type: UInt32
        if (!is_numeric(self.bindFlags)) show_error($"{_where} :: self.bindFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.bindFlags);

        // field: cpuAccessFlags, type: UInt32
        if (!is_numeric(self.cpuAccessFlags)) show_error($"{_where} :: self.cpuAccessFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.cpuAccessFlags);

        // field: miscFlags, type: UInt32
        if (!is_numeric(self.miscFlags)) show_error($"{_where} :: self.miscFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.miscFlags);

    }
}

/**
 * @func __ID3D11Texture2DDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11Texture2DDesc} 
 * @ignore 
 */
function __ID3D11Texture2DDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11Texture2DDesc();
    with (_inst)
    {
        // field: width, type: UInt32
        self.width = buffer_read(_buffer, buffer_u32);

        // field: height, type: UInt32
        self.height = buffer_read(_buffer, buffer_u32);

        // field: mipLevels, type: UInt32
        self.mipLevels = buffer_read(_buffer, buffer_u32);

        // field: arraySize, type: UInt32
        self.arraySize = buffer_read(_buffer, buffer_u32);

        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: sampleCount, type: UInt32
        self.sampleCount = buffer_read(_buffer, buffer_u32);

        // field: sampleQuality, type: UInt32
        self.sampleQuality = buffer_read(_buffer, buffer_u32);

        // field: usage, type: UInt32
        self.usage = buffer_read(_buffer, buffer_u32);

        // field: bindFlags, type: UInt32
        self.bindFlags = buffer_read(_buffer, buffer_u32);

        // field: cpuAccessFlags, type: UInt32
        self.cpuAccessFlags = buffer_read(_buffer, buffer_u32);

        // field: miscFlags, type: UInt32
        self.miscFlags = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11Texture3DDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11Texture3DDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11Texture3DDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: width, type: UInt32
        if (!is_numeric(self.width)) show_error($"{_where} :: self.width expected number", true);
        buffer_write(_buffer, buffer_u32, self.width);

        // field: height, type: UInt32
        if (!is_numeric(self.height)) show_error($"{_where} :: self.height expected number", true);
        buffer_write(_buffer, buffer_u32, self.height);

        // field: depth, type: UInt32
        if (!is_numeric(self.depth)) show_error($"{_where} :: self.depth expected number", true);
        buffer_write(_buffer, buffer_u32, self.depth);

        // field: mipLevels, type: UInt32
        if (!is_numeric(self.mipLevels)) show_error($"{_where} :: self.mipLevels expected number", true);
        buffer_write(_buffer, buffer_u32, self.mipLevels);

        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: usage, type: UInt32
        if (!is_numeric(self.usage)) show_error($"{_where} :: self.usage expected number", true);
        buffer_write(_buffer, buffer_u32, self.usage);

        // field: bindFlags, type: UInt32
        if (!is_numeric(self.bindFlags)) show_error($"{_where} :: self.bindFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.bindFlags);

        // field: cpuAccessFlags, type: UInt32
        if (!is_numeric(self.cpuAccessFlags)) show_error($"{_where} :: self.cpuAccessFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.cpuAccessFlags);

        // field: miscFlags, type: UInt32
        if (!is_numeric(self.miscFlags)) show_error($"{_where} :: self.miscFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.miscFlags);

    }
}

/**
 * @func __ID3D11Texture3DDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11Texture3DDesc} 
 * @ignore 
 */
function __ID3D11Texture3DDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11Texture3DDesc();
    with (_inst)
    {
        // field: width, type: UInt32
        self.width = buffer_read(_buffer, buffer_u32);

        // field: height, type: UInt32
        self.height = buffer_read(_buffer, buffer_u32);

        // field: depth, type: UInt32
        self.depth = buffer_read(_buffer, buffer_u32);

        // field: mipLevels, type: UInt32
        self.mipLevels = buffer_read(_buffer, buffer_u32);

        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: usage, type: UInt32
        self.usage = buffer_read(_buffer, buffer_u32);

        // field: bindFlags, type: UInt32
        self.bindFlags = buffer_read(_buffer, buffer_u32);

        // field: cpuAccessFlags, type: UInt32
        self.cpuAccessFlags = buffer_read(_buffer, buffer_u32);

        // field: miscFlags, type: UInt32
        self.miscFlags = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11ShaderResourceViewDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11ShaderResourceViewDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11ShaderResourceViewDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: viewDimension, type: UInt32
        if (!is_numeric(self.viewDimension)) show_error($"{_where} :: self.viewDimension expected number", true);
        buffer_write(_buffer, buffer_u32, self.viewDimension);

        // field: firstElement, type: UInt32
        if (!is_numeric(self.firstElement)) show_error($"{_where} :: self.firstElement expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstElement);

        // field: numElements, type: UInt32
        if (!is_numeric(self.numElements)) show_error($"{_where} :: self.numElements expected number", true);
        buffer_write(_buffer, buffer_u32, self.numElements);

        // field: flags, type: UInt32
        if (!is_numeric(self.flags)) show_error($"{_where} :: self.flags expected number", true);
        buffer_write(_buffer, buffer_u32, self.flags);

        // field: mostDetailedMip, type: UInt32
        if (!is_numeric(self.mostDetailedMip)) show_error($"{_where} :: self.mostDetailedMip expected number", true);
        buffer_write(_buffer, buffer_u32, self.mostDetailedMip);

        // field: mipLevels, type: UInt32
        if (!is_numeric(self.mipLevels)) show_error($"{_where} :: self.mipLevels expected number", true);
        buffer_write(_buffer, buffer_u32, self.mipLevels);

        // field: firstArraySlice, type: UInt32
        if (!is_numeric(self.firstArraySlice)) show_error($"{_where} :: self.firstArraySlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstArraySlice);

        // field: arraySize, type: UInt32
        if (!is_numeric(self.arraySize)) show_error($"{_where} :: self.arraySize expected number", true);
        buffer_write(_buffer, buffer_u32, self.arraySize);

        // field: first2DArrayFace, type: UInt32
        if (!is_numeric(self.first2DArrayFace)) show_error($"{_where} :: self.first2DArrayFace expected number", true);
        buffer_write(_buffer, buffer_u32, self.first2DArrayFace);

        // field: numCubes, type: UInt32
        if (!is_numeric(self.numCubes)) show_error($"{_where} :: self.numCubes expected number", true);
        buffer_write(_buffer, buffer_u32, self.numCubes);

    }
}

/**
 * @func __ID3D11ShaderResourceViewDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11ShaderResourceViewDesc} 
 * @ignore 
 */
function __ID3D11ShaderResourceViewDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11ShaderResourceViewDesc();
    with (_inst)
    {
        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: viewDimension, type: UInt32
        self.viewDimension = buffer_read(_buffer, buffer_u32);

        // field: firstElement, type: UInt32
        self.firstElement = buffer_read(_buffer, buffer_u32);

        // field: numElements, type: UInt32
        self.numElements = buffer_read(_buffer, buffer_u32);

        // field: flags, type: UInt32
        self.flags = buffer_read(_buffer, buffer_u32);

        // field: mostDetailedMip, type: UInt32
        self.mostDetailedMip = buffer_read(_buffer, buffer_u32);

        // field: mipLevels, type: UInt32
        self.mipLevels = buffer_read(_buffer, buffer_u32);

        // field: firstArraySlice, type: UInt32
        self.firstArraySlice = buffer_read(_buffer, buffer_u32);

        // field: arraySize, type: UInt32
        self.arraySize = buffer_read(_buffer, buffer_u32);

        // field: first2DArrayFace, type: UInt32
        self.first2DArrayFace = buffer_read(_buffer, buffer_u32);

        // field: numCubes, type: UInt32
        self.numCubes = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11RenderTargetViewDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11RenderTargetViewDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11RenderTargetViewDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: viewDimension, type: UInt32
        if (!is_numeric(self.viewDimension)) show_error($"{_where} :: self.viewDimension expected number", true);
        buffer_write(_buffer, buffer_u32, self.viewDimension);

        // field: firstElement, type: UInt32
        if (!is_numeric(self.firstElement)) show_error($"{_where} :: self.firstElement expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstElement);

        // field: numElements, type: UInt32
        if (!is_numeric(self.numElements)) show_error($"{_where} :: self.numElements expected number", true);
        buffer_write(_buffer, buffer_u32, self.numElements);

        // field: mipSlice, type: UInt32
        if (!is_numeric(self.mipSlice)) show_error($"{_where} :: self.mipSlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.mipSlice);

        // field: firstArraySlice, type: UInt32
        if (!is_numeric(self.firstArraySlice)) show_error($"{_where} :: self.firstArraySlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstArraySlice);

        // field: arraySize, type: UInt32
        if (!is_numeric(self.arraySize)) show_error($"{_where} :: self.arraySize expected number", true);
        buffer_write(_buffer, buffer_u32, self.arraySize);

        // field: firstWSlice, type: UInt32
        if (!is_numeric(self.firstWSlice)) show_error($"{_where} :: self.firstWSlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstWSlice);

        // field: wSize, type: UInt32
        if (!is_numeric(self.wSize)) show_error($"{_where} :: self.wSize expected number", true);
        buffer_write(_buffer, buffer_u32, self.wSize);

    }
}

/**
 * @func __ID3D11RenderTargetViewDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11RenderTargetViewDesc} 
 * @ignore 
 */
function __ID3D11RenderTargetViewDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11RenderTargetViewDesc();
    with (_inst)
    {
        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: viewDimension, type: UInt32
        self.viewDimension = buffer_read(_buffer, buffer_u32);

        // field: firstElement, type: UInt32
        self.firstElement = buffer_read(_buffer, buffer_u32);

        // field: numElements, type: UInt32
        self.numElements = buffer_read(_buffer, buffer_u32);

        // field: mipSlice, type: UInt32
        self.mipSlice = buffer_read(_buffer, buffer_u32);

        // field: firstArraySlice, type: UInt32
        self.firstArraySlice = buffer_read(_buffer, buffer_u32);

        // field: arraySize, type: UInt32
        self.arraySize = buffer_read(_buffer, buffer_u32);

        // field: firstWSlice, type: UInt32
        self.firstWSlice = buffer_read(_buffer, buffer_u32);

        // field: wSize, type: UInt32
        self.wSize = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11DepthStencilViewDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11DepthStencilViewDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11DepthStencilViewDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: viewDimension, type: UInt32
        if (!is_numeric(self.viewDimension)) show_error($"{_where} :: self.viewDimension expected number", true);
        buffer_write(_buffer, buffer_u32, self.viewDimension);

        // field: flags, type: UInt32
        if (!is_numeric(self.flags)) show_error($"{_where} :: self.flags expected number", true);
        buffer_write(_buffer, buffer_u32, self.flags);

        // field: mipSlice, type: UInt32
        if (!is_numeric(self.mipSlice)) show_error($"{_where} :: self.mipSlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.mipSlice);

        // field: firstArraySlice, type: UInt32
        if (!is_numeric(self.firstArraySlice)) show_error($"{_where} :: self.firstArraySlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstArraySlice);

        // field: arraySize, type: UInt32
        if (!is_numeric(self.arraySize)) show_error($"{_where} :: self.arraySize expected number", true);
        buffer_write(_buffer, buffer_u32, self.arraySize);

    }
}

/**
 * @func __ID3D11DepthStencilViewDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11DepthStencilViewDesc} 
 * @ignore 
 */
function __ID3D11DepthStencilViewDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11DepthStencilViewDesc();
    with (_inst)
    {
        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: viewDimension, type: UInt32
        self.viewDimension = buffer_read(_buffer, buffer_u32);

        // field: flags, type: UInt32
        self.flags = buffer_read(_buffer, buffer_u32);

        // field: mipSlice, type: UInt32
        self.mipSlice = buffer_read(_buffer, buffer_u32);

        // field: firstArraySlice, type: UInt32
        self.firstArraySlice = buffer_read(_buffer, buffer_u32);

        // field: arraySize, type: UInt32
        self.arraySize = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11UnorderedAccessViewDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11UnorderedAccessViewDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11UnorderedAccessViewDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: viewDimension, type: UInt32
        if (!is_numeric(self.viewDimension)) show_error($"{_where} :: self.viewDimension expected number", true);
        buffer_write(_buffer, buffer_u32, self.viewDimension);

        // field: firstElement, type: UInt32
        if (!is_numeric(self.firstElement)) show_error($"{_where} :: self.firstElement expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstElement);

        // field: numElements, type: UInt32
        if (!is_numeric(self.numElements)) show_error($"{_where} :: self.numElements expected number", true);
        buffer_write(_buffer, buffer_u32, self.numElements);

        // field: flags, type: UInt32
        if (!is_numeric(self.flags)) show_error($"{_where} :: self.flags expected number", true);
        buffer_write(_buffer, buffer_u32, self.flags);

        // field: mipSlice, type: UInt32
        if (!is_numeric(self.mipSlice)) show_error($"{_where} :: self.mipSlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.mipSlice);

        // field: firstArraySlice, type: UInt32
        if (!is_numeric(self.firstArraySlice)) show_error($"{_where} :: self.firstArraySlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstArraySlice);

        // field: arraySize, type: UInt32
        if (!is_numeric(self.arraySize)) show_error($"{_where} :: self.arraySize expected number", true);
        buffer_write(_buffer, buffer_u32, self.arraySize);

        // field: firstWSlice, type: UInt32
        if (!is_numeric(self.firstWSlice)) show_error($"{_where} :: self.firstWSlice expected number", true);
        buffer_write(_buffer, buffer_u32, self.firstWSlice);

        // field: wSize, type: UInt32
        if (!is_numeric(self.wSize)) show_error($"{_where} :: self.wSize expected number", true);
        buffer_write(_buffer, buffer_u32, self.wSize);

    }
}

/**
 * @func __ID3D11UnorderedAccessViewDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11UnorderedAccessViewDesc} 
 * @ignore 
 */
function __ID3D11UnorderedAccessViewDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11UnorderedAccessViewDesc();
    with (_inst)
    {
        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: viewDimension, type: UInt32
        self.viewDimension = buffer_read(_buffer, buffer_u32);

        // field: firstElement, type: UInt32
        self.firstElement = buffer_read(_buffer, buffer_u32);

        // field: numElements, type: UInt32
        self.numElements = buffer_read(_buffer, buffer_u32);

        // field: flags, type: UInt32
        self.flags = buffer_read(_buffer, buffer_u32);

        // field: mipSlice, type: UInt32
        self.mipSlice = buffer_read(_buffer, buffer_u32);

        // field: firstArraySlice, type: UInt32
        self.firstArraySlice = buffer_read(_buffer, buffer_u32);

        // field: arraySize, type: UInt32
        self.arraySize = buffer_read(_buffer, buffer_u32);

        // field: firstWSlice, type: UInt32
        self.firstWSlice = buffer_read(_buffer, buffer_u32);

        // field: wSize, type: UInt32
        self.wSize = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11InputElementDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11InputElementDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11InputElementDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: semanticName, type: String
        if (!is_string(self.semanticName)) show_error($"{_where} :: self.semanticName expected string", true);
        buffer_write(_buffer, buffer_u32, string_byte_length(self.semanticName));
        buffer_write(_buffer, buffer_string, self.semanticName);

        // field: semanticIndex, type: UInt32
        if (!is_numeric(self.semanticIndex)) show_error($"{_where} :: self.semanticIndex expected number", true);
        buffer_write(_buffer, buffer_u32, self.semanticIndex);

        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: inputSlot, type: UInt32
        if (!is_numeric(self.inputSlot)) show_error($"{_where} :: self.inputSlot expected number", true);
        buffer_write(_buffer, buffer_u32, self.inputSlot);

        // field: alignedByteOffset, type: UInt32
        if (!is_numeric(self.alignedByteOffset)) show_error($"{_where} :: self.alignedByteOffset expected number", true);
        buffer_write(_buffer, buffer_u32, self.alignedByteOffset);

        // field: inputSlotClass, type: UInt32
        if (!is_numeric(self.inputSlotClass)) show_error($"{_where} :: self.inputSlotClass expected number", true);
        buffer_write(_buffer, buffer_u32, self.inputSlotClass);

        // field: instanceDataStepRate, type: UInt32
        if (!is_numeric(self.instanceDataStepRate)) show_error($"{_where} :: self.instanceDataStepRate expected number", true);
        buffer_write(_buffer, buffer_u32, self.instanceDataStepRate);

    }
}

/**
 * @func __ID3D11InputElementDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11InputElementDesc} 
 * @ignore 
 */
function __ID3D11InputElementDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11InputElementDesc();
    with (_inst)
    {
        // field: semanticName, type: String
        buffer_read(_buffer, buffer_u32);
        self.semanticName = buffer_read(_buffer, buffer_string);

        // field: semanticIndex, type: UInt32
        self.semanticIndex = buffer_read(_buffer, buffer_u32);

        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: inputSlot, type: UInt32
        self.inputSlot = buffer_read(_buffer, buffer_u32);

        // field: alignedByteOffset, type: UInt32
        self.alignedByteOffset = buffer_read(_buffer, buffer_u32);

        // field: inputSlotClass, type: UInt32
        self.inputSlotClass = buffer_read(_buffer, buffer_u32);

        // field: instanceDataStepRate, type: UInt32
        self.instanceDataStepRate = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11StreamOutputDeclarationEntry_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11StreamOutputDeclarationEntry} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11StreamOutputDeclarationEntry_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: semanticName, type: String
        if (!is_string(self.semanticName)) show_error($"{_where} :: self.semanticName expected string", true);
        buffer_write(_buffer, buffer_u32, string_byte_length(self.semanticName));
        buffer_write(_buffer, buffer_string, self.semanticName);

        // field: stream, type: UInt32
        if (!is_numeric(self.stream)) show_error($"{_where} :: self.stream expected number", true);
        buffer_write(_buffer, buffer_u32, self.stream);

        // field: semanticIndex, type: UInt32
        if (!is_numeric(self.semanticIndex)) show_error($"{_where} :: self.semanticIndex expected number", true);
        buffer_write(_buffer, buffer_u32, self.semanticIndex);

        // field: startComponent, type: UInt32
        if (!is_numeric(self.startComponent)) show_error($"{_where} :: self.startComponent expected number", true);
        buffer_write(_buffer, buffer_u32, self.startComponent);

        // field: componentCount, type: UInt32
        if (!is_numeric(self.componentCount)) show_error($"{_where} :: self.componentCount expected number", true);
        buffer_write(_buffer, buffer_u32, self.componentCount);

        // field: outputSlot, type: UInt32
        if (!is_numeric(self.outputSlot)) show_error($"{_where} :: self.outputSlot expected number", true);
        buffer_write(_buffer, buffer_u32, self.outputSlot);

    }
}

/**
 * @func __ID3D11StreamOutputDeclarationEntry_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11StreamOutputDeclarationEntry} 
 * @ignore 
 */
function __ID3D11StreamOutputDeclarationEntry_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11StreamOutputDeclarationEntry();
    with (_inst)
    {
        // field: semanticName, type: String
        buffer_read(_buffer, buffer_u32);
        self.semanticName = buffer_read(_buffer, buffer_string);

        // field: stream, type: UInt32
        self.stream = buffer_read(_buffer, buffer_u32);

        // field: semanticIndex, type: UInt32
        self.semanticIndex = buffer_read(_buffer, buffer_u32);

        // field: startComponent, type: UInt32
        self.startComponent = buffer_read(_buffer, buffer_u32);

        // field: componentCount, type: UInt32
        self.componentCount = buffer_read(_buffer, buffer_u32);

        // field: outputSlot, type: UInt32
        self.outputSlot = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11ShaderCompileResult_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11ShaderCompileResult} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11ShaderCompileResult_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: hresult, type: Int32
        if (!is_numeric(self.hresult)) show_error($"{_where} :: self.hresult expected number", true);
        buffer_write(_buffer, buffer_s32, self.hresult);

        // field: bytecodeSize, type: UInt64
        if (!is_numeric(self.bytecodeSize)) show_error($"{_where} :: self.bytecodeSize expected number", true);
        buffer_write(_buffer, buffer_u64, self.bytecodeSize);

        // field: errorSize, type: UInt64
        if (!is_numeric(self.errorSize)) show_error($"{_where} :: self.errorSize expected number", true);
        buffer_write(_buffer, buffer_u64, self.errorSize);

    }
}

/**
 * @func __ID3D11ShaderCompileResult_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11ShaderCompileResult} 
 * @ignore 
 */
function __ID3D11ShaderCompileResult_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11ShaderCompileResult();
    with (_inst)
    {
        // field: hresult, type: Int32
        self.hresult = buffer_read(_buffer, buffer_s32);

        // field: bytecodeSize, type: UInt64
        self.bytecodeSize = buffer_read(_buffer, buffer_u64);

        // field: errorSize, type: UInt64
        self.errorSize = buffer_read(_buffer, buffer_u64);

    }

    return _inst;
}

/**
 * @func __ID3D11SamplerDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11SamplerDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11SamplerDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: filter, type: UInt32
        if (!is_numeric(self.filter)) show_error($"{_where} :: self.filter expected number", true);
        buffer_write(_buffer, buffer_u32, self.filter);

        // field: addressU, type: UInt32
        if (!is_numeric(self.addressU)) show_error($"{_where} :: self.addressU expected number", true);
        buffer_write(_buffer, buffer_u32, self.addressU);

        // field: addressV, type: UInt32
        if (!is_numeric(self.addressV)) show_error($"{_where} :: self.addressV expected number", true);
        buffer_write(_buffer, buffer_u32, self.addressV);

        // field: addressW, type: UInt32
        if (!is_numeric(self.addressW)) show_error($"{_where} :: self.addressW expected number", true);
        buffer_write(_buffer, buffer_u32, self.addressW);

        // field: mipLodBias, type: Float32
        if (!is_numeric(self.mipLodBias)) show_error($"{_where} :: self.mipLodBias expected number", true);
        buffer_write(_buffer, buffer_f32, self.mipLodBias);

        // field: maxAnisotropy, type: UInt32
        if (!is_numeric(self.maxAnisotropy)) show_error($"{_where} :: self.maxAnisotropy expected number", true);
        buffer_write(_buffer, buffer_u32, self.maxAnisotropy);

        // field: comparisonFunc, type: UInt32
        if (!is_numeric(self.comparisonFunc)) show_error($"{_where} :: self.comparisonFunc expected number", true);
        buffer_write(_buffer, buffer_u32, self.comparisonFunc);

        // field: borderColorR, type: Float32
        if (!is_numeric(self.borderColorR)) show_error($"{_where} :: self.borderColorR expected number", true);
        buffer_write(_buffer, buffer_f32, self.borderColorR);

        // field: borderColorG, type: Float32
        if (!is_numeric(self.borderColorG)) show_error($"{_where} :: self.borderColorG expected number", true);
        buffer_write(_buffer, buffer_f32, self.borderColorG);

        // field: borderColorB, type: Float32
        if (!is_numeric(self.borderColorB)) show_error($"{_where} :: self.borderColorB expected number", true);
        buffer_write(_buffer, buffer_f32, self.borderColorB);

        // field: borderColorA, type: Float32
        if (!is_numeric(self.borderColorA)) show_error($"{_where} :: self.borderColorA expected number", true);
        buffer_write(_buffer, buffer_f32, self.borderColorA);

        // field: minLod, type: Float32
        if (!is_numeric(self.minLod)) show_error($"{_where} :: self.minLod expected number", true);
        buffer_write(_buffer, buffer_f32, self.minLod);

        // field: maxLod, type: Float32
        if (!is_numeric(self.maxLod)) show_error($"{_where} :: self.maxLod expected number", true);
        buffer_write(_buffer, buffer_f32, self.maxLod);

    }
}

/**
 * @func __ID3D11SamplerDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11SamplerDesc} 
 * @ignore 
 */
function __ID3D11SamplerDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11SamplerDesc();
    with (_inst)
    {
        // field: filter, type: UInt32
        self.filter = buffer_read(_buffer, buffer_u32);

        // field: addressU, type: UInt32
        self.addressU = buffer_read(_buffer, buffer_u32);

        // field: addressV, type: UInt32
        self.addressV = buffer_read(_buffer, buffer_u32);

        // field: addressW, type: UInt32
        self.addressW = buffer_read(_buffer, buffer_u32);

        // field: mipLodBias, type: Float32
        self.mipLodBias = buffer_read(_buffer, buffer_f32);

        // field: maxAnisotropy, type: UInt32
        self.maxAnisotropy = buffer_read(_buffer, buffer_u32);

        // field: comparisonFunc, type: UInt32
        self.comparisonFunc = buffer_read(_buffer, buffer_u32);

        // field: borderColorR, type: Float32
        self.borderColorR = buffer_read(_buffer, buffer_f32);

        // field: borderColorG, type: Float32
        self.borderColorG = buffer_read(_buffer, buffer_f32);

        // field: borderColorB, type: Float32
        self.borderColorB = buffer_read(_buffer, buffer_f32);

        // field: borderColorA, type: Float32
        self.borderColorA = buffer_read(_buffer, buffer_f32);

        // field: minLod, type: Float32
        self.minLod = buffer_read(_buffer, buffer_f32);

        // field: maxLod, type: Float32
        self.maxLod = buffer_read(_buffer, buffer_f32);

    }

    return _inst;
}

/**
 * @func __ID3D11RasterizerDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11RasterizerDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11RasterizerDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: fillMode, type: UInt32
        if (!is_numeric(self.fillMode)) show_error($"{_where} :: self.fillMode expected number", true);
        buffer_write(_buffer, buffer_u32, self.fillMode);

        // field: cullMode, type: UInt32
        if (!is_numeric(self.cullMode)) show_error($"{_where} :: self.cullMode expected number", true);
        buffer_write(_buffer, buffer_u32, self.cullMode);

        // field: frontCounterClockwise, type: Bool
        if (!is_bool(self.frontCounterClockwise)) show_error($"{_where} :: self.frontCounterClockwise expected bool", true);
        buffer_write(_buffer, buffer_bool, self.frontCounterClockwise);

        // field: depthBias, type: Int32
        if (!is_numeric(self.depthBias)) show_error($"{_where} :: self.depthBias expected number", true);
        buffer_write(_buffer, buffer_s32, self.depthBias);

        // field: depthBiasClamp, type: Float32
        if (!is_numeric(self.depthBiasClamp)) show_error($"{_where} :: self.depthBiasClamp expected number", true);
        buffer_write(_buffer, buffer_f32, self.depthBiasClamp);

        // field: slopeScaledDepthBias, type: Float32
        if (!is_numeric(self.slopeScaledDepthBias)) show_error($"{_where} :: self.slopeScaledDepthBias expected number", true);
        buffer_write(_buffer, buffer_f32, self.slopeScaledDepthBias);

        // field: depthClipEnable, type: Bool
        if (!is_bool(self.depthClipEnable)) show_error($"{_where} :: self.depthClipEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.depthClipEnable);

        // field: scissorEnable, type: Bool
        if (!is_bool(self.scissorEnable)) show_error($"{_where} :: self.scissorEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.scissorEnable);

        // field: multisampleEnable, type: Bool
        if (!is_bool(self.multisampleEnable)) show_error($"{_where} :: self.multisampleEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.multisampleEnable);

        // field: antialiasedLineEnable, type: Bool
        if (!is_bool(self.antialiasedLineEnable)) show_error($"{_where} :: self.antialiasedLineEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.antialiasedLineEnable);

    }
}

/**
 * @func __ID3D11RasterizerDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11RasterizerDesc} 
 * @ignore 
 */
function __ID3D11RasterizerDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11RasterizerDesc();
    with (_inst)
    {
        // field: fillMode, type: UInt32
        self.fillMode = buffer_read(_buffer, buffer_u32);

        // field: cullMode, type: UInt32
        self.cullMode = buffer_read(_buffer, buffer_u32);

        // field: frontCounterClockwise, type: Bool
        self.frontCounterClockwise = buffer_read(_buffer, buffer_bool);

        // field: depthBias, type: Int32
        self.depthBias = buffer_read(_buffer, buffer_s32);

        // field: depthBiasClamp, type: Float32
        self.depthBiasClamp = buffer_read(_buffer, buffer_f32);

        // field: slopeScaledDepthBias, type: Float32
        self.slopeScaledDepthBias = buffer_read(_buffer, buffer_f32);

        // field: depthClipEnable, type: Bool
        self.depthClipEnable = buffer_read(_buffer, buffer_bool);

        // field: scissorEnable, type: Bool
        self.scissorEnable = buffer_read(_buffer, buffer_bool);

        // field: multisampleEnable, type: Bool
        self.multisampleEnable = buffer_read(_buffer, buffer_bool);

        // field: antialiasedLineEnable, type: Bool
        self.antialiasedLineEnable = buffer_read(_buffer, buffer_bool);

    }

    return _inst;
}

/**
 * @func __ID3D11RenderTargetBlendDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11RenderTargetBlendDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11RenderTargetBlendDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: blendEnable, type: Bool
        if (!is_bool(self.blendEnable)) show_error($"{_where} :: self.blendEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.blendEnable);

        // field: srcBlend, type: UInt32
        if (!is_numeric(self.srcBlend)) show_error($"{_where} :: self.srcBlend expected number", true);
        buffer_write(_buffer, buffer_u32, self.srcBlend);

        // field: destBlend, type: UInt32
        if (!is_numeric(self.destBlend)) show_error($"{_where} :: self.destBlend expected number", true);
        buffer_write(_buffer, buffer_u32, self.destBlend);

        // field: blendOp, type: UInt32
        if (!is_numeric(self.blendOp)) show_error($"{_where} :: self.blendOp expected number", true);
        buffer_write(_buffer, buffer_u32, self.blendOp);

        // field: srcBlendAlpha, type: UInt32
        if (!is_numeric(self.srcBlendAlpha)) show_error($"{_where} :: self.srcBlendAlpha expected number", true);
        buffer_write(_buffer, buffer_u32, self.srcBlendAlpha);

        // field: destBlendAlpha, type: UInt32
        if (!is_numeric(self.destBlendAlpha)) show_error($"{_where} :: self.destBlendAlpha expected number", true);
        buffer_write(_buffer, buffer_u32, self.destBlendAlpha);

        // field: blendOpAlpha, type: UInt32
        if (!is_numeric(self.blendOpAlpha)) show_error($"{_where} :: self.blendOpAlpha expected number", true);
        buffer_write(_buffer, buffer_u32, self.blendOpAlpha);

        // field: renderTargetWriteMask, type: UInt32
        if (!is_numeric(self.renderTargetWriteMask)) show_error($"{_where} :: self.renderTargetWriteMask expected number", true);
        buffer_write(_buffer, buffer_u32, self.renderTargetWriteMask);

    }
}

/**
 * @func __ID3D11RenderTargetBlendDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11RenderTargetBlendDesc} 
 * @ignore 
 */
function __ID3D11RenderTargetBlendDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11RenderTargetBlendDesc();
    with (_inst)
    {
        // field: blendEnable, type: Bool
        self.blendEnable = buffer_read(_buffer, buffer_bool);

        // field: srcBlend, type: UInt32
        self.srcBlend = buffer_read(_buffer, buffer_u32);

        // field: destBlend, type: UInt32
        self.destBlend = buffer_read(_buffer, buffer_u32);

        // field: blendOp, type: UInt32
        self.blendOp = buffer_read(_buffer, buffer_u32);

        // field: srcBlendAlpha, type: UInt32
        self.srcBlendAlpha = buffer_read(_buffer, buffer_u32);

        // field: destBlendAlpha, type: UInt32
        self.destBlendAlpha = buffer_read(_buffer, buffer_u32);

        // field: blendOpAlpha, type: UInt32
        self.blendOpAlpha = buffer_read(_buffer, buffer_u32);

        // field: renderTargetWriteMask, type: UInt32
        self.renderTargetWriteMask = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11DepthStencilOpDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11DepthStencilOpDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11DepthStencilOpDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: stencilFailOp, type: UInt32
        if (!is_numeric(self.stencilFailOp)) show_error($"{_where} :: self.stencilFailOp expected number", true);
        buffer_write(_buffer, buffer_u32, self.stencilFailOp);

        // field: stencilDepthFailOp, type: UInt32
        if (!is_numeric(self.stencilDepthFailOp)) show_error($"{_where} :: self.stencilDepthFailOp expected number", true);
        buffer_write(_buffer, buffer_u32, self.stencilDepthFailOp);

        // field: stencilPassOp, type: UInt32
        if (!is_numeric(self.stencilPassOp)) show_error($"{_where} :: self.stencilPassOp expected number", true);
        buffer_write(_buffer, buffer_u32, self.stencilPassOp);

        // field: stencilFunc, type: UInt32
        if (!is_numeric(self.stencilFunc)) show_error($"{_where} :: self.stencilFunc expected number", true);
        buffer_write(_buffer, buffer_u32, self.stencilFunc);

    }
}

/**
 * @func __ID3D11DepthStencilOpDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11DepthStencilOpDesc} 
 * @ignore 
 */
function __ID3D11DepthStencilOpDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11DepthStencilOpDesc();
    with (_inst)
    {
        // field: stencilFailOp, type: UInt32
        self.stencilFailOp = buffer_read(_buffer, buffer_u32);

        // field: stencilDepthFailOp, type: UInt32
        self.stencilDepthFailOp = buffer_read(_buffer, buffer_u32);

        // field: stencilPassOp, type: UInt32
        self.stencilPassOp = buffer_read(_buffer, buffer_u32);

        // field: stencilFunc, type: UInt32
        self.stencilFunc = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11QueryDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11QueryDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11QueryDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: query, type: UInt32
        if (!is_numeric(self.query)) show_error($"{_where} :: self.query expected number", true);
        buffer_write(_buffer, buffer_u32, self.query);

        // field: miscFlags, type: UInt32
        if (!is_numeric(self.miscFlags)) show_error($"{_where} :: self.miscFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.miscFlags);

    }
}

/**
 * @func __ID3D11QueryDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11QueryDesc} 
 * @ignore 
 */
function __ID3D11QueryDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11QueryDesc();
    with (_inst)
    {
        // field: query, type: UInt32
        self.query = buffer_read(_buffer, buffer_u32);

        // field: miscFlags, type: UInt32
        self.miscFlags = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11CounterDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11CounterDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11CounterDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: counter, type: UInt32
        if (!is_numeric(self.counter)) show_error($"{_where} :: self.counter expected number", true);
        buffer_write(_buffer, buffer_u32, self.counter);

        // field: miscFlags, type: UInt32
        if (!is_numeric(self.miscFlags)) show_error($"{_where} :: self.miscFlags expected number", true);
        buffer_write(_buffer, buffer_u32, self.miscFlags);

    }
}

/**
 * @func __ID3D11CounterDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11CounterDesc} 
 * @ignore 
 */
function __ID3D11CounterDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11CounterDesc();
    with (_inst)
    {
        // field: counter, type: UInt32
        self.counter = buffer_read(_buffer, buffer_u32);

        // field: miscFlags, type: UInt32
        self.miscFlags = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11CheckCounterResult_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11CheckCounterResult} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11CheckCounterResult_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: hresult, type: Int32
        if (!is_numeric(self.hresult)) show_error($"{_where} :: self.hresult expected number", true);
        buffer_write(_buffer, buffer_s32, self.hresult);

        // field: type, type: UInt32
        if (!is_numeric(self.type)) show_error($"{_where} :: self.type expected number", true);
        buffer_write(_buffer, buffer_u32, self.type);

        // field: activeCounters, type: UInt32
        if (!is_numeric(self.activeCounters)) show_error($"{_where} :: self.activeCounters expected number", true);
        buffer_write(_buffer, buffer_u32, self.activeCounters);

        // field: name, type: String
        if (!is_string(self.name)) show_error($"{_where} :: self.name expected string", true);
        buffer_write(_buffer, buffer_u32, string_byte_length(self.name));
        buffer_write(_buffer, buffer_string, self.name);

        // field: units, type: String
        if (!is_string(self.units)) show_error($"{_where} :: self.units expected string", true);
        buffer_write(_buffer, buffer_u32, string_byte_length(self.units));
        buffer_write(_buffer, buffer_string, self.units);

        // field: description, type: String
        if (!is_string(self.description)) show_error($"{_where} :: self.description expected string", true);
        buffer_write(_buffer, buffer_u32, string_byte_length(self.description));
        buffer_write(_buffer, buffer_string, self.description);

    }
}

/**
 * @func __ID3D11CheckCounterResult_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11CheckCounterResult} 
 * @ignore 
 */
function __ID3D11CheckCounterResult_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11CheckCounterResult();
    with (_inst)
    {
        // field: hresult, type: Int32
        self.hresult = buffer_read(_buffer, buffer_s32);

        // field: type, type: UInt32
        self.type = buffer_read(_buffer, buffer_u32);

        // field: activeCounters, type: UInt32
        self.activeCounters = buffer_read(_buffer, buffer_u32);

        // field: name, type: String
        buffer_read(_buffer, buffer_u32);
        self.name = buffer_read(_buffer, buffer_string);

        // field: units, type: String
        buffer_read(_buffer, buffer_u32);
        self.units = buffer_read(_buffer, buffer_string);

        // field: description, type: String
        buffer_read(_buffer, buffer_u32);
        self.description = buffer_read(_buffer, buffer_string);

    }

    return _inst;
}

/**
 * @func __ID3D11BlendStateBinding_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11BlendStateBinding} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11BlendStateBinding_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: state, type: UInt64
        if (!is_numeric(self.state)) show_error($"{_where} :: self.state expected number", true);
        buffer_write(_buffer, buffer_u64, self.state);

        // field: blendFactor, type: Float32[]
        if (!is_array(self.blendFactor)) show_error($"{_where} :: self.blendFactor expected array", true);
        var _length = array_length(self.blendFactor);
        buffer_write(_buffer, buffer_u32, _length);
        for (var _i = 0; _i < _length; ++_i)
        {
            if (!is_numeric(self.blendFactor[_i])) show_error($"{_where} :: self.blendFactor[_i] expected number", true);
            buffer_write(_buffer, buffer_f32, self.blendFactor[_i]);
        }

        // field: sampleMask, type: UInt32
        if (!is_numeric(self.sampleMask)) show_error($"{_where} :: self.sampleMask expected number", true);
        buffer_write(_buffer, buffer_u32, self.sampleMask);

    }
}

/**
 * @func __ID3D11BlendStateBinding_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11BlendStateBinding} 
 * @ignore 
 */
function __ID3D11BlendStateBinding_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11BlendStateBinding();
    with (_inst)
    {
        // field: state, type: UInt64
        self.state = buffer_read(_buffer, buffer_u64);

        // field: blendFactor, type: Float32[]
        var _length = buffer_read(_buffer, buffer_u32);
        self.blendFactor = array_create(_length);
        for (var _i = 0; _i < _length; ++_i)
        {
            self.blendFactor[_i] = buffer_read(_buffer, buffer_f32);
        }

        // field: sampleMask, type: UInt32
        self.sampleMask = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11DepthStencilStateBinding_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11DepthStencilStateBinding} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11DepthStencilStateBinding_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: state, type: UInt64
        if (!is_numeric(self.state)) show_error($"{_where} :: self.state expected number", true);
        buffer_write(_buffer, buffer_u64, self.state);

        // field: stencilRef, type: UInt32
        if (!is_numeric(self.stencilRef)) show_error($"{_where} :: self.stencilRef expected number", true);
        buffer_write(_buffer, buffer_u32, self.stencilRef);

    }
}

/**
 * @func __ID3D11DepthStencilStateBinding_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11DepthStencilStateBinding} 
 * @ignore 
 */
function __ID3D11DepthStencilStateBinding_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11DepthStencilStateBinding();
    with (_inst)
    {
        // field: state, type: UInt64
        self.state = buffer_read(_buffer, buffer_u64);

        // field: stencilRef, type: UInt32
        self.stencilRef = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11PredicationBinding_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11PredicationBinding} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11PredicationBinding_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: predicate, type: UInt64
        if (!is_numeric(self.predicate)) show_error($"{_where} :: self.predicate expected number", true);
        buffer_write(_buffer, buffer_u64, self.predicate);

        // field: predicateValue, type: Bool
        if (!is_bool(self.predicateValue)) show_error($"{_where} :: self.predicateValue expected bool", true);
        buffer_write(_buffer, buffer_bool, self.predicateValue);

    }
}

/**
 * @func __ID3D11PredicationBinding_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11PredicationBinding} 
 * @ignore 
 */
function __ID3D11PredicationBinding_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11PredicationBinding();
    with (_inst)
    {
        // field: predicate, type: UInt64
        self.predicate = buffer_read(_buffer, buffer_u64);

        // field: predicateValue, type: Bool
        self.predicateValue = buffer_read(_buffer, buffer_bool);

    }

    return _inst;
}

/**
 * @func __ID3D11VertexBufferBinding_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11VertexBufferBinding} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11VertexBufferBinding_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: buffer, type: UInt64
        if (!is_numeric(self.buffer)) show_error($"{_where} :: self.buffer expected number", true);
        buffer_write(_buffer, buffer_u64, self.buffer);

        // field: stride, type: UInt32
        if (!is_numeric(self.stride)) show_error($"{_where} :: self.stride expected number", true);
        buffer_write(_buffer, buffer_u32, self.stride);

        // field: offset, type: UInt32
        if (!is_numeric(self.offset)) show_error($"{_where} :: self.offset expected number", true);
        buffer_write(_buffer, buffer_u32, self.offset);

    }
}

/**
 * @func __ID3D11VertexBufferBinding_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11VertexBufferBinding} 
 * @ignore 
 */
function __ID3D11VertexBufferBinding_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11VertexBufferBinding();
    with (_inst)
    {
        // field: buffer, type: UInt64
        self.buffer = buffer_read(_buffer, buffer_u64);

        // field: stride, type: UInt32
        self.stride = buffer_read(_buffer, buffer_u32);

        // field: offset, type: UInt32
        self.offset = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11IndexBufferBinding_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11IndexBufferBinding} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11IndexBufferBinding_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: buffer, type: UInt64
        if (!is_numeric(self.buffer)) show_error($"{_where} :: self.buffer expected number", true);
        buffer_write(_buffer, buffer_u64, self.buffer);

        // field: format, type: UInt32
        if (!is_numeric(self.format)) show_error($"{_where} :: self.format expected number", true);
        buffer_write(_buffer, buffer_u32, self.format);

        // field: offset, type: UInt32
        if (!is_numeric(self.offset)) show_error($"{_where} :: self.offset expected number", true);
        buffer_write(_buffer, buffer_u32, self.offset);

    }
}

/**
 * @func __ID3D11IndexBufferBinding_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11IndexBufferBinding} 
 * @ignore 
 */
function __ID3D11IndexBufferBinding_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11IndexBufferBinding();
    with (_inst)
    {
        // field: buffer, type: UInt64
        self.buffer = buffer_read(_buffer, buffer_u64);

        // field: format, type: UInt32
        self.format = buffer_read(_buffer, buffer_u32);

        // field: offset, type: UInt32
        self.offset = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11Viewport_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11Viewport} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11Viewport_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: topLeftX, type: Float32
        if (!is_numeric(self.topLeftX)) show_error($"{_where} :: self.topLeftX expected number", true);
        buffer_write(_buffer, buffer_f32, self.topLeftX);

        // field: topLeftY, type: Float32
        if (!is_numeric(self.topLeftY)) show_error($"{_where} :: self.topLeftY expected number", true);
        buffer_write(_buffer, buffer_f32, self.topLeftY);

        // field: width, type: Float32
        if (!is_numeric(self.width)) show_error($"{_where} :: self.width expected number", true);
        buffer_write(_buffer, buffer_f32, self.width);

        // field: height, type: Float32
        if (!is_numeric(self.height)) show_error($"{_where} :: self.height expected number", true);
        buffer_write(_buffer, buffer_f32, self.height);

        // field: minDepth, type: Float32
        if (!is_numeric(self.minDepth)) show_error($"{_where} :: self.minDepth expected number", true);
        buffer_write(_buffer, buffer_f32, self.minDepth);

        // field: maxDepth, type: Float32
        if (!is_numeric(self.maxDepth)) show_error($"{_where} :: self.maxDepth expected number", true);
        buffer_write(_buffer, buffer_f32, self.maxDepth);

    }
}

/**
 * @func __ID3D11Viewport_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11Viewport} 
 * @ignore 
 */
function __ID3D11Viewport_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11Viewport();
    with (_inst)
    {
        // field: topLeftX, type: Float32
        self.topLeftX = buffer_read(_buffer, buffer_f32);

        // field: topLeftY, type: Float32
        self.topLeftY = buffer_read(_buffer, buffer_f32);

        // field: width, type: Float32
        self.width = buffer_read(_buffer, buffer_f32);

        // field: height, type: Float32
        self.height = buffer_read(_buffer, buffer_f32);

        // field: minDepth, type: Float32
        self.minDepth = buffer_read(_buffer, buffer_f32);

        // field: maxDepth, type: Float32
        self.maxDepth = buffer_read(_buffer, buffer_f32);

    }

    return _inst;
}

/**
 * @func __ID3D11Rect_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11Rect} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11Rect_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: left, type: Int32
        if (!is_numeric(self.left)) show_error($"{_where} :: self.left expected number", true);
        buffer_write(_buffer, buffer_s32, self.left);

        // field: top, type: Int32
        if (!is_numeric(self.top)) show_error($"{_where} :: self.top expected number", true);
        buffer_write(_buffer, buffer_s32, self.top);

        // field: right, type: Int32
        if (!is_numeric(self.right)) show_error($"{_where} :: self.right expected number", true);
        buffer_write(_buffer, buffer_s32, self.right);

        // field: bottom, type: Int32
        if (!is_numeric(self.bottom)) show_error($"{_where} :: self.bottom expected number", true);
        buffer_write(_buffer, buffer_s32, self.bottom);

    }
}

/**
 * @func __ID3D11Rect_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11Rect} 
 * @ignore 
 */
function __ID3D11Rect_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11Rect();
    with (_inst)
    {
        // field: left, type: Int32
        self.left = buffer_read(_buffer, buffer_s32);

        // field: top, type: Int32
        self.top = buffer_read(_buffer, buffer_s32);

        // field: right, type: Int32
        self.right = buffer_read(_buffer, buffer_s32);

        // field: bottom, type: Int32
        self.bottom = buffer_read(_buffer, buffer_s32);

    }

    return _inst;
}

/**
 * @func __ID3D11Box_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11Box} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11Box_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: left, type: UInt32
        if (!is_numeric(self.left)) show_error($"{_where} :: self.left expected number", true);
        buffer_write(_buffer, buffer_u32, self.left);

        // field: top, type: UInt32
        if (!is_numeric(self.top)) show_error($"{_where} :: self.top expected number", true);
        buffer_write(_buffer, buffer_u32, self.top);

        // field: front, type: UInt32
        if (!is_numeric(self.front)) show_error($"{_where} :: self.front expected number", true);
        buffer_write(_buffer, buffer_u32, self.front);

        // field: right, type: UInt32
        if (!is_numeric(self.right)) show_error($"{_where} :: self.right expected number", true);
        buffer_write(_buffer, buffer_u32, self.right);

        // field: bottom, type: UInt32
        if (!is_numeric(self.bottom)) show_error($"{_where} :: self.bottom expected number", true);
        buffer_write(_buffer, buffer_u32, self.bottom);

        // field: back, type: UInt32
        if (!is_numeric(self.back)) show_error($"{_where} :: self.back expected number", true);
        buffer_write(_buffer, buffer_u32, self.back);

    }
}

/**
 * @func __ID3D11Box_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11Box} 
 * @ignore 
 */
function __ID3D11Box_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11Box();
    with (_inst)
    {
        // field: left, type: UInt32
        self.left = buffer_read(_buffer, buffer_u32);

        // field: top, type: UInt32
        self.top = buffer_read(_buffer, buffer_u32);

        // field: front, type: UInt32
        self.front = buffer_read(_buffer, buffer_u32);

        // field: right, type: UInt32
        self.right = buffer_read(_buffer, buffer_u32);

        // field: bottom, type: UInt32
        self.bottom = buffer_read(_buffer, buffer_u32);

        // field: back, type: UInt32
        self.back = buffer_read(_buffer, buffer_u32);

    }

    return _inst;
}

/**
 * @func __ID3D11ShaderBinding_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11ShaderBinding} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11ShaderBinding_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: shader, type: UInt64
        if (!is_numeric(self.shader)) show_error($"{_where} :: self.shader expected number", true);
        buffer_write(_buffer, buffer_u64, self.shader);

        // field: classInstances, type: UInt64[]
        if (!is_array(self.classInstances)) show_error($"{_where} :: self.classInstances expected array", true);
        var _length = array_length(self.classInstances);
        buffer_write(_buffer, buffer_u32, _length);
        for (var _i = 0; _i < _length; ++_i)
        {
            if (!is_numeric(self.classInstances[_i])) show_error($"{_where} :: self.classInstances[_i] expected number", true);
            buffer_write(_buffer, buffer_u64, self.classInstances[_i]);
        }

    }
}

/**
 * @func __ID3D11ShaderBinding_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11ShaderBinding} 
 * @ignore 
 */
function __ID3D11ShaderBinding_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11ShaderBinding();
    with (_inst)
    {
        // field: shader, type: UInt64
        self.shader = buffer_read(_buffer, buffer_u64);

        // field: classInstances, type: UInt64[]
        var _length = buffer_read(_buffer, buffer_u32);
        self.classInstances = array_create(_length);
        for (var _i = 0; _i < _length; ++_i)
        {
            self.classInstances[_i] = buffer_read(_buffer, buffer_u64);
        }

    }

    return _inst;
}

/**
 * @func __ID3D11ClassInstanceDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11ClassInstanceDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11ClassInstanceDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: instanceId, type: UInt32
        if (!is_numeric(self.instanceId)) show_error($"{_where} :: self.instanceId expected number", true);
        buffer_write(_buffer, buffer_u32, self.instanceId);

        // field: instanceIndex, type: UInt32
        if (!is_numeric(self.instanceIndex)) show_error($"{_where} :: self.instanceIndex expected number", true);
        buffer_write(_buffer, buffer_u32, self.instanceIndex);

        // field: typeId, type: UInt32
        if (!is_numeric(self.typeId)) show_error($"{_where} :: self.typeId expected number", true);
        buffer_write(_buffer, buffer_u32, self.typeId);

        // field: constantBuffer, type: UInt32
        if (!is_numeric(self.constantBuffer)) show_error($"{_where} :: self.constantBuffer expected number", true);
        buffer_write(_buffer, buffer_u32, self.constantBuffer);

        // field: baseConstantBufferOffset, type: UInt32
        if (!is_numeric(self.baseConstantBufferOffset)) show_error($"{_where} :: self.baseConstantBufferOffset expected number", true);
        buffer_write(_buffer, buffer_u32, self.baseConstantBufferOffset);

        // field: baseTexture, type: UInt32
        if (!is_numeric(self.baseTexture)) show_error($"{_where} :: self.baseTexture expected number", true);
        buffer_write(_buffer, buffer_u32, self.baseTexture);

        // field: baseSampler, type: UInt32
        if (!is_numeric(self.baseSampler)) show_error($"{_where} :: self.baseSampler expected number", true);
        buffer_write(_buffer, buffer_u32, self.baseSampler);

        // field: created, type: Bool
        if (!is_bool(self.created)) show_error($"{_where} :: self.created expected bool", true);
        buffer_write(_buffer, buffer_bool, self.created);

    }
}

/**
 * @func __ID3D11ClassInstanceDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11ClassInstanceDesc} 
 * @ignore 
 */
function __ID3D11ClassInstanceDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11ClassInstanceDesc();
    with (_inst)
    {
        // field: instanceId, type: UInt32
        self.instanceId = buffer_read(_buffer, buffer_u32);

        // field: instanceIndex, type: UInt32
        self.instanceIndex = buffer_read(_buffer, buffer_u32);

        // field: typeId, type: UInt32
        self.typeId = buffer_read(_buffer, buffer_u32);

        // field: constantBuffer, type: UInt32
        self.constantBuffer = buffer_read(_buffer, buffer_u32);

        // field: baseConstantBufferOffset, type: UInt32
        self.baseConstantBufferOffset = buffer_read(_buffer, buffer_u32);

        // field: baseTexture, type: UInt32
        self.baseTexture = buffer_read(_buffer, buffer_u32);

        // field: baseSampler, type: UInt32
        self.baseSampler = buffer_read(_buffer, buffer_u32);

        // field: created, type: Bool
        self.created = buffer_read(_buffer, buffer_bool);

    }

    return _inst;
}

/**
 * @func __ID3D11CreateHandleResult_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11CreateHandleResult} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11CreateHandleResult_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: hresult, type: Int32
        if (!is_numeric(self.hresult)) show_error($"{_where} :: self.hresult expected number", true);
        buffer_write(_buffer, buffer_s32, self.hresult);

        // field: handle, type: UInt64
        if (!is_numeric(self.handle)) show_error($"{_where} :: self.handle expected number", true);
        buffer_write(_buffer, buffer_u64, self.handle);

    }
}

/**
 * @func __ID3D11CreateHandleResult_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11CreateHandleResult} 
 * @ignore 
 */
function __ID3D11CreateHandleResult_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11CreateHandleResult();
    with (_inst)
    {
        // field: hresult, type: Int32
        self.hresult = buffer_read(_buffer, buffer_s32);

        // field: handle, type: UInt64
        self.handle = buffer_read(_buffer, buffer_u64);

    }

    return _inst;
}

/**
 * @func __ID3D11BlendDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11BlendDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11BlendDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: alphaToCoverageEnable, type: Bool
        if (!is_bool(self.alphaToCoverageEnable)) show_error($"{_where} :: self.alphaToCoverageEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.alphaToCoverageEnable);

        // field: independentBlendEnable, type: Bool
        if (!is_bool(self.independentBlendEnable)) show_error($"{_where} :: self.independentBlendEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.independentBlendEnable);

        // field: renderTargets, type: struct ID3D11RenderTargetBlendDesc[]
        if (!is_array(self.renderTargets)) show_error($"{_where} :: self.renderTargets expected array", true);
        var _length = array_length(self.renderTargets);
        buffer_write(_buffer, buffer_u32, _length);
        for (var _i = 0; _i < _length; ++_i)
        {
            if (self.renderTargets[_i].__uid != 2265759682) show_error($"{_where} :: self.renderTargets[_i] expected ID3D11RenderTargetBlendDesc", true);
            __ID3D11RenderTargetBlendDesc_encode(self.renderTargets[_i], _buffer, buffer_tell(_buffer), _where);
        }

    }
}

/**
 * @func __ID3D11BlendDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11BlendDesc} 
 * @ignore 
 */
function __ID3D11BlendDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11BlendDesc();
    with (_inst)
    {
        // field: alphaToCoverageEnable, type: Bool
        self.alphaToCoverageEnable = buffer_read(_buffer, buffer_bool);

        // field: independentBlendEnable, type: Bool
        self.independentBlendEnable = buffer_read(_buffer, buffer_bool);

        // field: renderTargets, type: struct ID3D11RenderTargetBlendDesc[]
        var _length = buffer_read(_buffer, buffer_u32);
        self.renderTargets = array_create(_length);
        for (var _i = 0; _i < _length; ++_i)
        {
            self.renderTargets[_i] = __ID3D11RenderTargetBlendDesc_decode(_buffer, buffer_tell(_buffer));
        }

    }

    return _inst;
}

/**
 * @func __ID3D11DepthStencilDesc_encode(_inst, _buffer, _offset, _where)
 * @param {Struct.ID3D11DepthStencilDesc} _inst
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @param {String} _where
 * @ignore 
 */
function __ID3D11DepthStencilDesc_encode(_inst, _buffer, _offset, _where = _GMFUNCTION_)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);
    with (_inst)
    {
        // field: depthEnable, type: Bool
        if (!is_bool(self.depthEnable)) show_error($"{_where} :: self.depthEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.depthEnable);

        // field: depthWriteMask, type: UInt32
        if (!is_numeric(self.depthWriteMask)) show_error($"{_where} :: self.depthWriteMask expected number", true);
        buffer_write(_buffer, buffer_u32, self.depthWriteMask);

        // field: depthFunc, type: UInt32
        if (!is_numeric(self.depthFunc)) show_error($"{_where} :: self.depthFunc expected number", true);
        buffer_write(_buffer, buffer_u32, self.depthFunc);

        // field: stencilEnable, type: Bool
        if (!is_bool(self.stencilEnable)) show_error($"{_where} :: self.stencilEnable expected bool", true);
        buffer_write(_buffer, buffer_bool, self.stencilEnable);

        // field: stencilReadMask, type: UInt32
        if (!is_numeric(self.stencilReadMask)) show_error($"{_where} :: self.stencilReadMask expected number", true);
        buffer_write(_buffer, buffer_u32, self.stencilReadMask);

        // field: stencilWriteMask, type: UInt32
        if (!is_numeric(self.stencilWriteMask)) show_error($"{_where} :: self.stencilWriteMask expected number", true);
        buffer_write(_buffer, buffer_u32, self.stencilWriteMask);

        // field: frontFace, type: struct ID3D11DepthStencilOpDesc
        if (self.frontFace.__uid != 1005052320) show_error($"{_where} :: self.frontFace expected ID3D11DepthStencilOpDesc", true);
        __ID3D11DepthStencilOpDesc_encode(self.frontFace, _buffer, buffer_tell(_buffer), _where);

        // field: backFace, type: struct ID3D11DepthStencilOpDesc
        if (self.backFace.__uid != 1005052320) show_error($"{_where} :: self.backFace expected ID3D11DepthStencilOpDesc", true);
        __ID3D11DepthStencilOpDesc_encode(self.backFace, _buffer, buffer_tell(_buffer), _where);

    }
}

/**
 * @func __ID3D11DepthStencilDesc_decode(_buffer, _offset)
 * @param {Id.Buffer} _buffer
 * @param {Real} _offset
 * @returns {Struct.ID3D11DepthStencilDesc} 
 * @ignore 
 */
function __ID3D11DepthStencilDesc_decode(_buffer, _offset)
{
    buffer_seek(_buffer, buffer_seek_start, _offset);

    _inst = new ID3D11DepthStencilDesc();
    with (_inst)
    {
        // field: depthEnable, type: Bool
        self.depthEnable = buffer_read(_buffer, buffer_bool);

        // field: depthWriteMask, type: UInt32
        self.depthWriteMask = buffer_read(_buffer, buffer_u32);

        // field: depthFunc, type: UInt32
        self.depthFunc = buffer_read(_buffer, buffer_u32);

        // field: stencilEnable, type: Bool
        self.stencilEnable = buffer_read(_buffer, buffer_bool);

        // field: stencilReadMask, type: UInt32
        self.stencilReadMask = buffer_read(_buffer, buffer_u32);

        // field: stencilWriteMask, type: UInt32
        self.stencilWriteMask = buffer_read(_buffer, buffer_u32);

        // field: frontFace, type: struct ID3D11DepthStencilOpDesc
        self.frontFace = __ID3D11DepthStencilOpDesc_decode(_buffer, buffer_tell(_buffer));

        // field: backFace, type: struct ID3D11DepthStencilOpDesc
        self.backFace = __ID3D11DepthStencilOpDesc_decode(_buffer, buffer_tell(_buffer));

    }

    return _inst;
}

// #####################################################################
// # Functions
// #####################################################################

/**
 * @returns {Struct.ID3D11Version} 
 */
function id3d11_get_version()
{
    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_get_version(buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11Version_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

// Skipping function id3d11_is_initialized (no wrapper is required)


// Skipping function id3d11_get_last_hresult (no wrapper is required)


/**
 * @returns {Real} 
 */
function id3d11_get_device_handle()
{
    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_get_device_handle(buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @returns {Real} 
 */
function id3d11_get_context_handle()
{
    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_get_context_handle(buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @returns {Real} 
 */
function id3d11_get_swapchain_handle()
{
    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_get_swapchain_handle(buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _handle
 * @param {Enum.ID3D11HandleKind} _interfaceKind
 * @returns {Real} 
 */
function id3d11_handle_query_interface(_handle, _interfaceKind)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _handle, type: UInt64
    if (!is_numeric(_handle)) show_error($"{_GMFUNCTION_} :: _handle expected number", true);
    buffer_write(__args_buffer, buffer_u64, _handle);

    // param: _interfaceKind, type: enum ID3D11HandleKind

    if (!is_numeric(_interfaceKind)) show_error($"{_GMFUNCTION_} :: _interfaceKind expected number", true);
    buffer_write(__args_buffer, buffer_u32, _interfaceKind);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_handle_query_interface(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _handle
 * @returns {Bool} 
 */
function id3d11_handle_is_valid(_handle)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _handle, type: UInt64
    if (!is_numeric(_handle)) show_error($"{_GMFUNCTION_} :: _handle expected number", true);
    buffer_write(__args_buffer, buffer_u64, _handle);

    var _return_value = __id3d11_handle_is_valid(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _handle
 * @returns {Enum.ID3D11HandleKind} 
 */
function id3d11_handle_get_kind(_handle)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _handle, type: UInt64
    if (!is_numeric(_handle)) show_error($"{_GMFUNCTION_} :: _handle expected number", true);
    buffer_write(__args_buffer, buffer_u64, _handle);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_handle_get_kind(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u32);
    return _result;
}

/**
 * @param {Real} _handle
 * @returns {Bool} 
 */
function id3d11_handle_release(_handle)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _handle, type: UInt64
    if (!is_numeric(_handle)) show_error($"{_GMFUNCTION_} :: _handle expected number", true);
    buffer_write(__args_buffer, buffer_u64, _handle);

    var _return_value = __id3d11_handle_release(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _device
 * @returns {Enum.ID3D11FeatureLevel} 
 */
function id3d11_device_get_feature_level(_device)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_get_feature_level(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u32);
    return _result;
}

/**
 * @param {Real} _device
 * @returns {Real} 
 */
function id3d11_device_get_creation_flags(_device)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    var _return_value = __id3d11_device_get_creation_flags(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _device
 * @returns {Real} 
 */
function id3d11_device_get_removed_reason(_device)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    var _return_value = __id3d11_device_get_removed_reason(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _device
 * @returns {Real} 
 */
function id3d11_device_get_exception_mode(_device)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    var _return_value = __id3d11_device_get_exception_mode(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _device
 * @param {Real} _raiseFlags
 * @returns {Real} 
 */
function id3d11_device_set_exception_mode(_device, _raiseFlags)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _raiseFlags, type: UInt32
    if (!is_numeric(_raiseFlags)) show_error($"{_GMFUNCTION_} :: _raiseFlags expected number", true);
    buffer_write(__args_buffer, buffer_u32, _raiseFlags);

    var _return_value = __id3d11_device_set_exception_mode(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _device
 * @returns {Real} 
 */
function id3d11_device_get_immediate_context(_device)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_get_immediate_context(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _format
 * @returns {Struct.ID3D11FormatSupportResult} 
 */
function id3d11_device_check_format_support(_device, _format)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _format, type: UInt32
    if (!is_numeric(_format)) show_error($"{_GMFUNCTION_} :: _format expected number", true);
    buffer_write(__args_buffer, buffer_u32, _format);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_check_format_support(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11FormatSupportResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _format
 * @param {Real} _sampleCount
 * @returns {Struct.ID3D11MultisampleQualityResult} 
 */
function id3d11_device_check_multisample_quality_levels(_device, _format, _sampleCount)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _format, type: UInt32
    if (!is_numeric(_format)) show_error($"{_GMFUNCTION_} :: _format expected number", true);
    buffer_write(__args_buffer, buffer_u32, _format);

    // param: _sampleCount, type: UInt32
    if (!is_numeric(_sampleCount)) show_error($"{_GMFUNCTION_} :: _sampleCount expected number", true);
    buffer_write(__args_buffer, buffer_u32, _sampleCount);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_check_multisample_quality_levels(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11MultisampleQualityResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @returns {Struct.ID3D11CounterInfo} 
 */
function id3d11_device_get_counter_info(_device)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_get_counter_info(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CounterInfo_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11BufferDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_buffer(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11BufferDesc
    if (_desc.__uid != 3031618682) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11BufferDesc", true);
    __ID3D11BufferDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_buffer(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11BufferDesc} _desc
 * @param {Id.Buffer} _data
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_buffer_with_data(_device, _desc, _data)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11BufferDesc
    if (_desc.__uid != 3031618682) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11BufferDesc", true);
    __ID3D11BufferDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    // param: _data, type: Buffer
    if (!buffer_exists(_data)) show_error($"{_GMFUNCTION_} :: _data expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_data), buffer_get_size(_data));

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_buffer_with_data(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _bufferHandle
 * @returns {Struct.ID3D11BufferDesc} 
 */
function id3d11_buffer_get_desc(_bufferHandle)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _bufferHandle, type: UInt64
    if (!is_numeric(_bufferHandle)) show_error($"{_GMFUNCTION_} :: _bufferHandle expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bufferHandle);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_buffer_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11BufferDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _deviceChild
 * @returns {Real} 
 */
function id3d11_device_child_get_device(_deviceChild)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _deviceChild, type: UInt64
    if (!is_numeric(_deviceChild)) show_error($"{_GMFUNCTION_} :: _deviceChild expected number", true);
    buffer_write(__args_buffer, buffer_u64, _deviceChild);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_child_get_device(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _resource
 * @returns {Enum.ID3D11ResourceDimension} 
 */
function id3d11_resource_get_dimension(_resource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_resource_get_dimension(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u32);
    return _result;
}

/**
 * @param {Real} _resource
 * @returns {Real} 
 */
function id3d11_resource_get_eviction_priority(_resource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    var _return_value = __id3d11_resource_get_eviction_priority(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _resource
 * @param {Real} _evictionPriority
 * @returns {Bool} 
 */
function id3d11_resource_set_eviction_priority(_resource, _evictionPriority)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    // param: _evictionPriority, type: UInt32
    if (!is_numeric(_evictionPriority)) show_error($"{_GMFUNCTION_} :: _evictionPriority expected number", true);
    buffer_write(__args_buffer, buffer_u32, _evictionPriority);

    var _return_value = __id3d11_resource_set_eviction_priority(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11Texture1DDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_texture1d(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11Texture1DDesc
    if (_desc.__uid != 1346893864) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11Texture1DDesc", true);
    __ID3D11Texture1DDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_texture1d(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11Texture1DDesc} _desc
 * @param {Array[Struct.ID3D11SubresourceData]} _subresources
 * @param {Id.Buffer} _data
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_texture1d_with_data(_device, _desc, _subresources, _data)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11Texture1DDesc
    if (_desc.__uid != 1346893864) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11Texture1DDesc", true);
    __ID3D11Texture1DDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    // param: _subresources, type: struct ID3D11SubresourceData[]
    if (!is_array(_subresources)) show_error($"{_GMFUNCTION_} :: _subresources expected array", true);
    var _length = array_length(_subresources);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_subresources[_i].__uid != 351177001) show_error($"{_GMFUNCTION_} :: _subresources[_i] expected ID3D11SubresourceData", true);
        __ID3D11SubresourceData_encode(_subresources[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    // param: _data, type: Buffer
    if (!buffer_exists(_data)) show_error($"{_GMFUNCTION_} :: _data expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_data), buffer_get_size(_data));

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_texture1d_with_data(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11Texture2DDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_texture2d(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11Texture2DDesc
    if (_desc.__uid != 712135135) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11Texture2DDesc", true);
    __ID3D11Texture2DDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_texture2d(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11Texture2DDesc} _desc
 * @param {Array[Struct.ID3D11SubresourceData]} _subresources
 * @param {Id.Buffer} _data
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_texture2d_with_data(_device, _desc, _subresources, _data)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11Texture2DDesc
    if (_desc.__uid != 712135135) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11Texture2DDesc", true);
    __ID3D11Texture2DDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    // param: _subresources, type: struct ID3D11SubresourceData[]
    if (!is_array(_subresources)) show_error($"{_GMFUNCTION_} :: _subresources expected array", true);
    var _length = array_length(_subresources);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_subresources[_i].__uid != 351177001) show_error($"{_GMFUNCTION_} :: _subresources[_i] expected ID3D11SubresourceData", true);
        __ID3D11SubresourceData_encode(_subresources[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    // param: _data, type: Buffer
    if (!buffer_exists(_data)) show_error($"{_GMFUNCTION_} :: _data expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_data), buffer_get_size(_data));

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_texture2d_with_data(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11Texture3DDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_texture3d(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11Texture3DDesc
    if (_desc.__uid != 695491914) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11Texture3DDesc", true);
    __ID3D11Texture3DDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_texture3d(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11Texture3DDesc} _desc
 * @param {Array[Struct.ID3D11SubresourceData]} _subresources
 * @param {Id.Buffer} _data
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_texture3d_with_data(_device, _desc, _subresources, _data)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11Texture3DDesc
    if (_desc.__uid != 695491914) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11Texture3DDesc", true);
    __ID3D11Texture3DDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    // param: _subresources, type: struct ID3D11SubresourceData[]
    if (!is_array(_subresources)) show_error($"{_GMFUNCTION_} :: _subresources expected array", true);
    var _length = array_length(_subresources);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_subresources[_i].__uid != 351177001) show_error($"{_GMFUNCTION_} :: _subresources[_i] expected ID3D11SubresourceData", true);
        __ID3D11SubresourceData_encode(_subresources[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    // param: _data, type: Buffer
    if (!buffer_exists(_data)) show_error($"{_GMFUNCTION_} :: _data expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_data), buffer_get_size(_data));

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_texture3d_with_data(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _texture
 * @returns {Struct.ID3D11Texture1DDesc} 
 */
function id3d11_texture1d_get_desc(_texture)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _texture, type: UInt64
    if (!is_numeric(_texture)) show_error($"{_GMFUNCTION_} :: _texture expected number", true);
    buffer_write(__args_buffer, buffer_u64, _texture);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_texture1d_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11Texture1DDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _texture
 * @returns {Struct.ID3D11Texture2DDesc} 
 */
function id3d11_texture2d_get_desc(_texture)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _texture, type: UInt64
    if (!is_numeric(_texture)) show_error($"{_GMFUNCTION_} :: _texture expected number", true);
    buffer_write(__args_buffer, buffer_u64, _texture);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_texture2d_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11Texture2DDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _texture
 * @returns {Struct.ID3D11Texture3DDesc} 
 */
function id3d11_texture3d_get_desc(_texture)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _texture, type: UInt64
    if (!is_numeric(_texture)) show_error($"{_GMFUNCTION_} :: _texture expected number", true);
    buffer_write(__args_buffer, buffer_u64, _texture);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_texture3d_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11Texture3DDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_shader_resource_view_default(_device, _resource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_shader_resource_view_default(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @param {Struct.ID3D11ShaderResourceViewDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_shader_resource_view(_device, _resource, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    // param: _desc, type: struct ID3D11ShaderResourceViewDesc
    if (_desc.__uid != 2369398716) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11ShaderResourceViewDesc", true);
    __ID3D11ShaderResourceViewDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_shader_resource_view(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_render_target_view_default(_device, _resource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_render_target_view_default(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @param {Struct.ID3D11RenderTargetViewDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_render_target_view(_device, _resource, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    // param: _desc, type: struct ID3D11RenderTargetViewDesc
    if (_desc.__uid != 3224692808) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11RenderTargetViewDesc", true);
    __ID3D11RenderTargetViewDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_render_target_view(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_depth_stencil_view_default(_device, _resource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_depth_stencil_view_default(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @param {Struct.ID3D11DepthStencilViewDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_depth_stencil_view(_device, _resource, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    // param: _desc, type: struct ID3D11DepthStencilViewDesc
    if (_desc.__uid != 2918764966) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11DepthStencilViewDesc", true);
    __ID3D11DepthStencilViewDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_depth_stencil_view(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_unordered_access_view_default(_device, _resource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_unordered_access_view_default(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Real} _resource
 * @param {Struct.ID3D11UnorderedAccessViewDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_unordered_access_view(_device, _resource, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    // param: _desc, type: struct ID3D11UnorderedAccessViewDesc
    if (_desc.__uid != 783930313) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11UnorderedAccessViewDesc", true);
    __ID3D11UnorderedAccessViewDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_unordered_access_view(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _view
 * @returns {Real} 
 */
function id3d11_view_get_resource(_view)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _view, type: UInt64
    if (!is_numeric(_view)) show_error($"{_GMFUNCTION_} :: _view expected number", true);
    buffer_write(__args_buffer, buffer_u64, _view);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_view_get_resource(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _view
 * @returns {Struct.ID3D11ShaderResourceViewDesc} 
 */
function id3d11_shader_resource_view_get_desc(_view)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _view, type: UInt64
    if (!is_numeric(_view)) show_error($"{_GMFUNCTION_} :: _view expected number", true);
    buffer_write(__args_buffer, buffer_u64, _view);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_shader_resource_view_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderResourceViewDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _view
 * @returns {Struct.ID3D11RenderTargetViewDesc} 
 */
function id3d11_render_target_view_get_desc(_view)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _view, type: UInt64
    if (!is_numeric(_view)) show_error($"{_GMFUNCTION_} :: _view expected number", true);
    buffer_write(__args_buffer, buffer_u64, _view);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_render_target_view_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11RenderTargetViewDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _view
 * @returns {Struct.ID3D11DepthStencilViewDesc} 
 */
function id3d11_depth_stencil_view_get_desc(_view)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _view, type: UInt64
    if (!is_numeric(_view)) show_error($"{_GMFUNCTION_} :: _view expected number", true);
    buffer_write(__args_buffer, buffer_u64, _view);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_depth_stencil_view_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11DepthStencilViewDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _view
 * @returns {Struct.ID3D11UnorderedAccessViewDesc} 
 */
function id3d11_unordered_access_view_get_desc(_view)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _view, type: UInt64
    if (!is_numeric(_view)) show_error($"{_GMFUNCTION_} :: _view expected number", true);
    buffer_write(__args_buffer, buffer_u64, _view);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_unordered_access_view_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11UnorderedAccessViewDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {String} _source
 * @param {String} _sourceName
 * @param {String} _entryPoint
 * @param {String} _target
 * @param {Real} _flags1
 * @param {Real} _flags2
 * @param {Id.Buffer} _bytecode
 * @param {Id.Buffer} _errors
 * @returns {Struct.ID3D11ShaderCompileResult} 
 */
function id3d11_compile_shader(_source, _sourceName, _entryPoint, _target, _flags1, _flags2, _bytecode, _errors)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _source, type: String
    if (!is_string(_source)) show_error($"{_GMFUNCTION_} :: _source expected string", true);
    buffer_write(__args_buffer, buffer_u32, string_byte_length(_source));
    buffer_write(__args_buffer, buffer_string, _source);

    // param: _sourceName, type: String
    if (!is_string(_sourceName)) show_error($"{_GMFUNCTION_} :: _sourceName expected string", true);
    buffer_write(__args_buffer, buffer_u32, string_byte_length(_sourceName));
    buffer_write(__args_buffer, buffer_string, _sourceName);

    // param: _entryPoint, type: String
    if (!is_string(_entryPoint)) show_error($"{_GMFUNCTION_} :: _entryPoint expected string", true);
    buffer_write(__args_buffer, buffer_u32, string_byte_length(_entryPoint));
    buffer_write(__args_buffer, buffer_string, _entryPoint);

    // param: _target, type: String
    if (!is_string(_target)) show_error($"{_GMFUNCTION_} :: _target expected string", true);
    buffer_write(__args_buffer, buffer_u32, string_byte_length(_target));
    buffer_write(__args_buffer, buffer_string, _target);

    // param: _flags1, type: UInt32
    if (!is_numeric(_flags1)) show_error($"{_GMFUNCTION_} :: _flags1 expected number", true);
    buffer_write(__args_buffer, buffer_u32, _flags1);

    // param: _flags2, type: UInt32
    if (!is_numeric(_flags2)) show_error($"{_GMFUNCTION_} :: _flags2 expected number", true);
    buffer_write(__args_buffer, buffer_u32, _flags2);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _errors, type: Buffer
    if (!buffer_exists(_errors)) show_error($"{_GMFUNCTION_} :: _errors expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_errors), buffer_get_size(_errors));

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_compile_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderCompileResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Id.Buffer} _bytecode
 * @param {Real} _bytecodeSize
 * @param {Real} _classLinkage
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_vertex_shader(_device, _bytecode, _bytecodeSize, _classLinkage)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    // param: _classLinkage, type: UInt64
    if (!is_numeric(_classLinkage)) show_error($"{_GMFUNCTION_} :: _classLinkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _classLinkage);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_vertex_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Id.Buffer} _bytecode
 * @param {Real} _bytecodeSize
 * @param {Real} _classLinkage
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_hull_shader(_device, _bytecode, _bytecodeSize, _classLinkage)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    // param: _classLinkage, type: UInt64
    if (!is_numeric(_classLinkage)) show_error($"{_GMFUNCTION_} :: _classLinkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _classLinkage);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_hull_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Id.Buffer} _bytecode
 * @param {Real} _bytecodeSize
 * @param {Real} _classLinkage
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_domain_shader(_device, _bytecode, _bytecodeSize, _classLinkage)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    // param: _classLinkage, type: UInt64
    if (!is_numeric(_classLinkage)) show_error($"{_GMFUNCTION_} :: _classLinkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _classLinkage);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_domain_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Id.Buffer} _bytecode
 * @param {Real} _bytecodeSize
 * @param {Real} _classLinkage
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_geometry_shader(_device, _bytecode, _bytecodeSize, _classLinkage)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    // param: _classLinkage, type: UInt64
    if (!is_numeric(_classLinkage)) show_error($"{_GMFUNCTION_} :: _classLinkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _classLinkage);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_geometry_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Id.Buffer} _bytecode
 * @param {Real} _bytecodeSize
 * @param {Real} _classLinkage
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_pixel_shader(_device, _bytecode, _bytecodeSize, _classLinkage)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    // param: _classLinkage, type: UInt64
    if (!is_numeric(_classLinkage)) show_error($"{_GMFUNCTION_} :: _classLinkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _classLinkage);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_pixel_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Id.Buffer} _bytecode
 * @param {Real} _bytecodeSize
 * @param {Real} _classLinkage
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_compute_shader(_device, _bytecode, _bytecodeSize, _classLinkage)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    // param: _classLinkage, type: UInt64
    if (!is_numeric(_classLinkage)) show_error($"{_GMFUNCTION_} :: _classLinkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _classLinkage);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_compute_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Id.Buffer} _bytecode
 * @param {Real} _bytecodeSize
 * @param {Array[Struct.ID3D11StreamOutputDeclarationEntry]} _declarations
 * @param {Array[Real]} _bufferStrides
 * @param {Real} _rasterizedStream
 * @param {Real} _classLinkage
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_geometry_shader_with_stream_output(_device, _bytecode, _bytecodeSize, _declarations, _bufferStrides, _rasterizedStream, _classLinkage)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _bytecode, type: Buffer
    if (!buffer_exists(_bytecode)) show_error($"{_GMFUNCTION_} :: _bytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_bytecode), buffer_get_size(_bytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    // param: _declarations, type: struct ID3D11StreamOutputDeclarationEntry[]
    if (!is_array(_declarations)) show_error($"{_GMFUNCTION_} :: _declarations expected array", true);
    var _length = array_length(_declarations);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_declarations[_i].__uid != 4192113024) show_error($"{_GMFUNCTION_} :: _declarations[_i] expected ID3D11StreamOutputDeclarationEntry", true);
        __ID3D11StreamOutputDeclarationEntry_encode(_declarations[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    // param: _bufferStrides, type: UInt32[]
    if (!is_array(_bufferStrides)) show_error($"{_GMFUNCTION_} :: _bufferStrides expected array", true);
    var _length = array_length(_bufferStrides);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_bufferStrides[_i])) show_error($"{_GMFUNCTION_} :: _bufferStrides[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u32, _bufferStrides[_i]);
    }

    // param: _rasterizedStream, type: UInt32
    if (!is_numeric(_rasterizedStream)) show_error($"{_GMFUNCTION_} :: _rasterizedStream expected number", true);
    buffer_write(__args_buffer, buffer_u32, _rasterizedStream);

    // param: _classLinkage, type: UInt64
    if (!is_numeric(_classLinkage)) show_error($"{_GMFUNCTION_} :: _classLinkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _classLinkage);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_geometry_shader_with_stream_output(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Array[Struct.ID3D11InputElementDesc]} _elements
 * @param {Id.Buffer} _shaderBytecode
 * @param {Real} _bytecodeSize
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_input_layout(_device, _elements, _shaderBytecode, _bytecodeSize)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _elements, type: struct ID3D11InputElementDesc[]
    if (!is_array(_elements)) show_error($"{_GMFUNCTION_} :: _elements expected array", true);
    var _length = array_length(_elements);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_elements[_i].__uid != 3369076812) show_error($"{_GMFUNCTION_} :: _elements[_i] expected ID3D11InputElementDesc", true);
        __ID3D11InputElementDesc_encode(_elements[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    // param: _shaderBytecode, type: Buffer
    if (!buffer_exists(_shaderBytecode)) show_error($"{_GMFUNCTION_} :: _shaderBytecode expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_shaderBytecode), buffer_get_size(_shaderBytecode));

    // param: _bytecodeSize, type: UInt64
    if (!is_numeric(_bytecodeSize)) show_error($"{_GMFUNCTION_} :: _bytecodeSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _bytecodeSize);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_input_layout(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_class_linkage(_device)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_class_linkage(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11SamplerDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_sampler_state(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11SamplerDesc
    if (_desc.__uid != 213418622) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11SamplerDesc", true);
    __ID3D11SamplerDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_sampler_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _state
 * @returns {Struct.ID3D11SamplerDesc} 
 */
function id3d11_sampler_state_get_desc(_state)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _state, type: UInt64
    if (!is_numeric(_state)) show_error($"{_GMFUNCTION_} :: _state expected number", true);
    buffer_write(__args_buffer, buffer_u64, _state);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_sampler_state_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11SamplerDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11RasterizerDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_rasterizer_state(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11RasterizerDesc
    if (_desc.__uid != 1976543893) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11RasterizerDesc", true);
    __ID3D11RasterizerDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_rasterizer_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _state
 * @returns {Struct.ID3D11RasterizerDesc} 
 */
function id3d11_rasterizer_state_get_desc(_state)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _state, type: UInt64
    if (!is_numeric(_state)) show_error($"{_GMFUNCTION_} :: _state expected number", true);
    buffer_write(__args_buffer, buffer_u64, _state);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_rasterizer_state_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11RasterizerDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11BlendDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_blend_state(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11BlendDesc
    if (_desc.__uid != 728541829) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11BlendDesc", true);
    __ID3D11BlendDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_blend_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _state
 * @returns {Struct.ID3D11BlendDesc} 
 */
function id3d11_blend_state_get_desc(_state)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _state, type: UInt64
    if (!is_numeric(_state)) show_error($"{_GMFUNCTION_} :: _state expected number", true);
    buffer_write(__args_buffer, buffer_u64, _state);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_blend_state_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11BlendDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11DepthStencilDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_depth_stencil_state(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11DepthStencilDesc
    if (_desc.__uid != 1807275747) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11DepthStencilDesc", true);
    __ID3D11DepthStencilDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_depth_stencil_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _state
 * @returns {Struct.ID3D11DepthStencilDesc} 
 */
function id3d11_depth_stencil_state_get_desc(_state)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _state, type: UInt64
    if (!is_numeric(_state)) show_error($"{_GMFUNCTION_} :: _state expected number", true);
    buffer_write(__args_buffer, buffer_u64, _state);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_depth_stencil_state_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11DepthStencilDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11QueryDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_query(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11QueryDesc
    if (_desc.__uid != 3852865306) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11QueryDesc", true);
    __ID3D11QueryDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_query(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11QueryDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_predicate(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11QueryDesc
    if (_desc.__uid != 3852865306) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11QueryDesc", true);
    __ID3D11QueryDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_predicate(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11CounterDesc} _desc
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_device_create_counter(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11CounterDesc
    if (_desc.__uid != 663643394) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11CounterDesc", true);
    __ID3D11CounterDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_create_counter(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _asynchronous
 * @returns {Real} 
 */
function id3d11_asynchronous_get_data_size(_asynchronous)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _asynchronous, type: UInt64
    if (!is_numeric(_asynchronous)) show_error($"{_GMFUNCTION_} :: _asynchronous expected number", true);
    buffer_write(__args_buffer, buffer_u64, _asynchronous);

    var _return_value = __id3d11_asynchronous_get_data_size(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _query
 * @returns {Struct.ID3D11QueryDesc} 
 */
function id3d11_query_get_desc(_query)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _query, type: UInt64
    if (!is_numeric(_query)) show_error($"{_GMFUNCTION_} :: _query expected number", true);
    buffer_write(__args_buffer, buffer_u64, _query);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_query_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11QueryDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _counter
 * @returns {Struct.ID3D11CounterDesc} 
 */
function id3d11_counter_get_desc(_counter)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _counter, type: UInt64
    if (!is_numeric(_counter)) show_error($"{_GMFUNCTION_} :: _counter expected number", true);
    buffer_write(__args_buffer, buffer_u64, _counter);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_counter_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CounterDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _device
 * @param {Struct.ID3D11CounterDesc} _desc
 * @returns {Struct.ID3D11CheckCounterResult} 
 */
function id3d11_device_check_counter(_device, _desc)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: UInt64
    if (!is_numeric(_device)) show_error($"{_GMFUNCTION_} :: _device expected number", true);
    buffer_write(__args_buffer, buffer_u64, _device);

    // param: _desc, type: struct ID3D11CounterDesc
    if (_desc.__uid != 663643394) show_error($"{_GMFUNCTION_} :: _desc expected ID3D11CounterDesc", true);
    __ID3D11CounterDesc_encode(_desc, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_check_counter(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CheckCounterResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _asynchronous
 * @returns {Bool} 
 */
function id3d11_device_context_begin(_context, _asynchronous)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _asynchronous, type: UInt64
    if (!is_numeric(_asynchronous)) show_error($"{_GMFUNCTION_} :: _asynchronous expected number", true);
    buffer_write(__args_buffer, buffer_u64, _asynchronous);

    var _return_value = __id3d11_device_context_begin(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _asynchronous
 * @returns {Bool} 
 */
function id3d11_device_context_end(_context, _asynchronous)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _asynchronous, type: UInt64
    if (!is_numeric(_asynchronous)) show_error($"{_GMFUNCTION_} :: _asynchronous expected number", true);
    buffer_write(__args_buffer, buffer_u64, _asynchronous);

    var _return_value = __id3d11_device_context_end(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _asynchronous
 * @param {Id.Buffer} _data
 * @param {Real} _dataSize
 * @param {Real} _flags
 * @returns {Real} 
 */
function id3d11_device_context_get_data(_context, _asynchronous, _data, _dataSize, _flags)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _asynchronous, type: UInt64
    if (!is_numeric(_asynchronous)) show_error($"{_GMFUNCTION_} :: _asynchronous expected number", true);
    buffer_write(__args_buffer, buffer_u64, _asynchronous);

    // param: _data, type: Buffer
    if (!buffer_exists(_data)) show_error($"{_GMFUNCTION_} :: _data expected Id.Buffer", true);
    __ID3D11_queue_buffer(buffer_get_address(_data), buffer_get_size(_data));

    // param: _dataSize, type: UInt64
    if (!is_numeric(_dataSize)) show_error($"{_GMFUNCTION_} :: _dataSize expected number", true);
    buffer_write(__args_buffer, buffer_u64, _dataSize);

    // param: _flags, type: UInt32
    if (!is_numeric(_flags)) show_error($"{_GMFUNCTION_} :: _flags expected number", true);
    buffer_write(__args_buffer, buffer_u32, _flags);

    var _return_value = __id3d11_device_context_get_data(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Bool} 
 */
function id3d11_device_context_flush(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var _return_value = __id3d11_device_context_flush(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _indexCount
 * @param {Real} _startIndexLocation
 * @param {Real} _baseVertexLocation
 * @returns {Bool} 
 */
function id3d11_device_context_draw_indexed(_context, _indexCount, _startIndexLocation, _baseVertexLocation)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _indexCount, type: UInt32
    if (!is_numeric(_indexCount)) show_error($"{_GMFUNCTION_} :: _indexCount expected number", true);
    buffer_write(__args_buffer, buffer_u32, _indexCount);

    // param: _startIndexLocation, type: UInt32
    if (!is_numeric(_startIndexLocation)) show_error($"{_GMFUNCTION_} :: _startIndexLocation expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startIndexLocation);

    // param: _baseVertexLocation, type: Int32
    if (!is_numeric(_baseVertexLocation)) show_error($"{_GMFUNCTION_} :: _baseVertexLocation expected number", true);
    buffer_write(__args_buffer, buffer_s32, _baseVertexLocation);

    var _return_value = __id3d11_device_context_draw_indexed(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _vertexCount
 * @param {Real} _startVertexLocation
 * @returns {Bool} 
 */
function id3d11_device_context_draw(_context, _vertexCount, _startVertexLocation)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _vertexCount, type: UInt32
    if (!is_numeric(_vertexCount)) show_error($"{_GMFUNCTION_} :: _vertexCount expected number", true);
    buffer_write(__args_buffer, buffer_u32, _vertexCount);

    // param: _startVertexLocation, type: UInt32
    if (!is_numeric(_startVertexLocation)) show_error($"{_GMFUNCTION_} :: _startVertexLocation expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startVertexLocation);

    var _return_value = __id3d11_device_context_draw(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _indexCountPerInstance
 * @param {Real} _instanceCount
 * @param {Real} _startIndexLocation
 * @param {Real} _baseVertexLocation
 * @param {Real} _startInstanceLocation
 * @returns {Bool} 
 */
function id3d11_device_context_draw_indexed_instanced(_context, _indexCountPerInstance, _instanceCount, _startIndexLocation, _baseVertexLocation, _startInstanceLocation)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _indexCountPerInstance, type: UInt32
    if (!is_numeric(_indexCountPerInstance)) show_error($"{_GMFUNCTION_} :: _indexCountPerInstance expected number", true);
    buffer_write(__args_buffer, buffer_u32, _indexCountPerInstance);

    // param: _instanceCount, type: UInt32
    if (!is_numeric(_instanceCount)) show_error($"{_GMFUNCTION_} :: _instanceCount expected number", true);
    buffer_write(__args_buffer, buffer_u32, _instanceCount);

    // param: _startIndexLocation, type: UInt32
    if (!is_numeric(_startIndexLocation)) show_error($"{_GMFUNCTION_} :: _startIndexLocation expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startIndexLocation);

    // param: _baseVertexLocation, type: Int32
    if (!is_numeric(_baseVertexLocation)) show_error($"{_GMFUNCTION_} :: _baseVertexLocation expected number", true);
    buffer_write(__args_buffer, buffer_s32, _baseVertexLocation);

    // param: _startInstanceLocation, type: UInt32
    if (!is_numeric(_startInstanceLocation)) show_error($"{_GMFUNCTION_} :: _startInstanceLocation expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startInstanceLocation);

    var _return_value = __id3d11_device_context_draw_indexed_instanced(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _vertexCountPerInstance
 * @param {Real} _instanceCount
 * @param {Real} _startVertexLocation
 * @param {Real} _startInstanceLocation
 * @returns {Bool} 
 */
function id3d11_device_context_draw_instanced(_context, _vertexCountPerInstance, _instanceCount, _startVertexLocation, _startInstanceLocation)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _vertexCountPerInstance, type: UInt32
    if (!is_numeric(_vertexCountPerInstance)) show_error($"{_GMFUNCTION_} :: _vertexCountPerInstance expected number", true);
    buffer_write(__args_buffer, buffer_u32, _vertexCountPerInstance);

    // param: _instanceCount, type: UInt32
    if (!is_numeric(_instanceCount)) show_error($"{_GMFUNCTION_} :: _instanceCount expected number", true);
    buffer_write(__args_buffer, buffer_u32, _instanceCount);

    // param: _startVertexLocation, type: UInt32
    if (!is_numeric(_startVertexLocation)) show_error($"{_GMFUNCTION_} :: _startVertexLocation expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startVertexLocation);

    // param: _startInstanceLocation, type: UInt32
    if (!is_numeric(_startInstanceLocation)) show_error($"{_GMFUNCTION_} :: _startInstanceLocation expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startInstanceLocation);

    var _return_value = __id3d11_device_context_draw_instanced(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Bool} 
 */
function id3d11_device_context_draw_auto(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var _return_value = __id3d11_device_context_draw_auto(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _argumentBuffer
 * @param {Real} _alignedByteOffset
 * @returns {Bool} 
 */
function id3d11_device_context_draw_indexed_instanced_indirect(_context, _argumentBuffer, _alignedByteOffset)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _argumentBuffer, type: UInt64
    if (!is_numeric(_argumentBuffer)) show_error($"{_GMFUNCTION_} :: _argumentBuffer expected number", true);
    buffer_write(__args_buffer, buffer_u64, _argumentBuffer);

    // param: _alignedByteOffset, type: UInt32
    if (!is_numeric(_alignedByteOffset)) show_error($"{_GMFUNCTION_} :: _alignedByteOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _alignedByteOffset);

    var _return_value = __id3d11_device_context_draw_indexed_instanced_indirect(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _argumentBuffer
 * @param {Real} _alignedByteOffset
 * @returns {Bool} 
 */
function id3d11_device_context_draw_instanced_indirect(_context, _argumentBuffer, _alignedByteOffset)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _argumentBuffer, type: UInt64
    if (!is_numeric(_argumentBuffer)) show_error($"{_GMFUNCTION_} :: _argumentBuffer expected number", true);
    buffer_write(__args_buffer, buffer_u64, _argumentBuffer);

    // param: _alignedByteOffset, type: UInt32
    if (!is_numeric(_alignedByteOffset)) show_error($"{_GMFUNCTION_} :: _alignedByteOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _alignedByteOffset);

    var _return_value = __id3d11_device_context_draw_instanced_indirect(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _threadGroupCountX
 * @param {Real} _threadGroupCountY
 * @param {Real} _threadGroupCountZ
 * @returns {Bool} 
 */
function id3d11_device_context_dispatch(_context, _threadGroupCountX, _threadGroupCountY, _threadGroupCountZ)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _threadGroupCountX, type: UInt32
    if (!is_numeric(_threadGroupCountX)) show_error($"{_GMFUNCTION_} :: _threadGroupCountX expected number", true);
    buffer_write(__args_buffer, buffer_u32, _threadGroupCountX);

    // param: _threadGroupCountY, type: UInt32
    if (!is_numeric(_threadGroupCountY)) show_error($"{_GMFUNCTION_} :: _threadGroupCountY expected number", true);
    buffer_write(__args_buffer, buffer_u32, _threadGroupCountY);

    // param: _threadGroupCountZ, type: UInt32
    if (!is_numeric(_threadGroupCountZ)) show_error($"{_GMFUNCTION_} :: _threadGroupCountZ expected number", true);
    buffer_write(__args_buffer, buffer_u32, _threadGroupCountZ);

    var _return_value = __id3d11_device_context_dispatch(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _argumentBuffer
 * @param {Real} _alignedByteOffset
 * @returns {Bool} 
 */
function id3d11_device_context_dispatch_indirect(_context, _argumentBuffer, _alignedByteOffset)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _argumentBuffer, type: UInt64
    if (!is_numeric(_argumentBuffer)) show_error($"{_GMFUNCTION_} :: _argumentBuffer expected number", true);
    buffer_write(__args_buffer, buffer_u64, _argumentBuffer);

    // param: _alignedByteOffset, type: UInt32
    if (!is_numeric(_alignedByteOffset)) show_error($"{_GMFUNCTION_} :: _alignedByteOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _alignedByteOffset);

    var _return_value = __id3d11_device_context_dispatch_indirect(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _destinationResource
 * @param {Real} _destinationSubresource
 * @param {Real} _destinationX
 * @param {Real} _destinationY
 * @param {Real} _destinationZ
 * @param {Real} _sourceResource
 * @param {Real} _sourceSubresource
 * @param {Bool} _useSourceBox
 * @param {Struct.ID3D11Box} _sourceBox
 * @returns {Bool} 
 */
function id3d11_device_context_copy_subresource_region(_context, _destinationResource, _destinationSubresource, _destinationX, _destinationY, _destinationZ, _sourceResource, _sourceSubresource, _useSourceBox, _sourceBox)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _destinationResource, type: UInt64
    if (!is_numeric(_destinationResource)) show_error($"{_GMFUNCTION_} :: _destinationResource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _destinationResource);

    // param: _destinationSubresource, type: UInt32
    if (!is_numeric(_destinationSubresource)) show_error($"{_GMFUNCTION_} :: _destinationSubresource expected number", true);
    buffer_write(__args_buffer, buffer_u32, _destinationSubresource);

    // param: _destinationX, type: UInt32
    if (!is_numeric(_destinationX)) show_error($"{_GMFUNCTION_} :: _destinationX expected number", true);
    buffer_write(__args_buffer, buffer_u32, _destinationX);

    // param: _destinationY, type: UInt32
    if (!is_numeric(_destinationY)) show_error($"{_GMFUNCTION_} :: _destinationY expected number", true);
    buffer_write(__args_buffer, buffer_u32, _destinationY);

    // param: _destinationZ, type: UInt32
    if (!is_numeric(_destinationZ)) show_error($"{_GMFUNCTION_} :: _destinationZ expected number", true);
    buffer_write(__args_buffer, buffer_u32, _destinationZ);

    // param: _sourceResource, type: UInt64
    if (!is_numeric(_sourceResource)) show_error($"{_GMFUNCTION_} :: _sourceResource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _sourceResource);

    // param: _sourceSubresource, type: UInt32
    if (!is_numeric(_sourceSubresource)) show_error($"{_GMFUNCTION_} :: _sourceSubresource expected number", true);
    buffer_write(__args_buffer, buffer_u32, _sourceSubresource);

    // param: _useSourceBox, type: Bool
    if (!is_bool(_useSourceBox)) show_error($"{_GMFUNCTION_} :: _useSourceBox expected bool", true);
    buffer_write(__args_buffer, buffer_bool, _useSourceBox);

    // param: _sourceBox, type: struct ID3D11Box
    if (_sourceBox.__uid != 2185347734) show_error($"{_GMFUNCTION_} :: _sourceBox expected ID3D11Box", true);
    __ID3D11Box_encode(_sourceBox, __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);

    var _return_value = __id3d11_device_context_copy_subresource_region(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _destinationResource
 * @param {Real} _sourceResource
 * @returns {Bool} 
 */
function id3d11_device_context_copy_resource(_context, _destinationResource, _sourceResource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _destinationResource, type: UInt64
    if (!is_numeric(_destinationResource)) show_error($"{_GMFUNCTION_} :: _destinationResource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _destinationResource);

    // param: _sourceResource, type: UInt64
    if (!is_numeric(_sourceResource)) show_error($"{_GMFUNCTION_} :: _sourceResource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _sourceResource);

    var _return_value = __id3d11_device_context_copy_resource(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _destinationBuffer
 * @param {Real} _destinationAlignedByteOffset
 * @param {Real} _sourceView
 * @returns {Bool} 
 */
function id3d11_device_context_copy_structure_count(_context, _destinationBuffer, _destinationAlignedByteOffset, _sourceView)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _destinationBuffer, type: UInt64
    if (!is_numeric(_destinationBuffer)) show_error($"{_GMFUNCTION_} :: _destinationBuffer expected number", true);
    buffer_write(__args_buffer, buffer_u64, _destinationBuffer);

    // param: _destinationAlignedByteOffset, type: UInt32
    if (!is_numeric(_destinationAlignedByteOffset)) show_error($"{_GMFUNCTION_} :: _destinationAlignedByteOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _destinationAlignedByteOffset);

    // param: _sourceView, type: UInt64
    if (!is_numeric(_sourceView)) show_error($"{_GMFUNCTION_} :: _sourceView expected number", true);
    buffer_write(__args_buffer, buffer_u64, _sourceView);

    var _return_value = __id3d11_device_context_copy_structure_count(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _renderTargetView
 * @param {Real} _red
 * @param {Real} _green
 * @param {Real} _blue
 * @param {Real} _alpha
 * @returns {Bool} 
 */
function id3d11_device_context_clear_render_target_view(_context, _renderTargetView, _red, _green, _blue, _alpha)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _renderTargetView, type: UInt64
    if (!is_numeric(_renderTargetView)) show_error($"{_GMFUNCTION_} :: _renderTargetView expected number", true);
    buffer_write(__args_buffer, buffer_u64, _renderTargetView);

    // param: _red, type: Float32
    if (!is_numeric(_red)) show_error($"{_GMFUNCTION_} :: _red expected number", true);
    buffer_write(__args_buffer, buffer_f32, _red);

    // param: _green, type: Float32
    if (!is_numeric(_green)) show_error($"{_GMFUNCTION_} :: _green expected number", true);
    buffer_write(__args_buffer, buffer_f32, _green);

    // param: _blue, type: Float32
    if (!is_numeric(_blue)) show_error($"{_GMFUNCTION_} :: _blue expected number", true);
    buffer_write(__args_buffer, buffer_f32, _blue);

    // param: _alpha, type: Float32
    if (!is_numeric(_alpha)) show_error($"{_GMFUNCTION_} :: _alpha expected number", true);
    buffer_write(__args_buffer, buffer_f32, _alpha);

    var _return_value = __id3d11_device_context_clear_render_target_view(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _unorderedAccessView
 * @param {Real} _value0
 * @param {Real} _value1
 * @param {Real} _value2
 * @param {Real} _value3
 * @returns {Bool} 
 */
function id3d11_device_context_clear_unordered_access_view_uint(_context, _unorderedAccessView, _value0, _value1, _value2, _value3)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _unorderedAccessView, type: UInt64
    if (!is_numeric(_unorderedAccessView)) show_error($"{_GMFUNCTION_} :: _unorderedAccessView expected number", true);
    buffer_write(__args_buffer, buffer_u64, _unorderedAccessView);

    // param: _value0, type: UInt32
    if (!is_numeric(_value0)) show_error($"{_GMFUNCTION_} :: _value0 expected number", true);
    buffer_write(__args_buffer, buffer_u32, _value0);

    // param: _value1, type: UInt32
    if (!is_numeric(_value1)) show_error($"{_GMFUNCTION_} :: _value1 expected number", true);
    buffer_write(__args_buffer, buffer_u32, _value1);

    // param: _value2, type: UInt32
    if (!is_numeric(_value2)) show_error($"{_GMFUNCTION_} :: _value2 expected number", true);
    buffer_write(__args_buffer, buffer_u32, _value2);

    // param: _value3, type: UInt32
    if (!is_numeric(_value3)) show_error($"{_GMFUNCTION_} :: _value3 expected number", true);
    buffer_write(__args_buffer, buffer_u32, _value3);

    var _return_value = __id3d11_device_context_clear_unordered_access_view_uint(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _unorderedAccessView
 * @param {Real} _value0
 * @param {Real} _value1
 * @param {Real} _value2
 * @param {Real} _value3
 * @returns {Bool} 
 */
function id3d11_device_context_clear_unordered_access_view_float(_context, _unorderedAccessView, _value0, _value1, _value2, _value3)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _unorderedAccessView, type: UInt64
    if (!is_numeric(_unorderedAccessView)) show_error($"{_GMFUNCTION_} :: _unorderedAccessView expected number", true);
    buffer_write(__args_buffer, buffer_u64, _unorderedAccessView);

    // param: _value0, type: Float32
    if (!is_numeric(_value0)) show_error($"{_GMFUNCTION_} :: _value0 expected number", true);
    buffer_write(__args_buffer, buffer_f32, _value0);

    // param: _value1, type: Float32
    if (!is_numeric(_value1)) show_error($"{_GMFUNCTION_} :: _value1 expected number", true);
    buffer_write(__args_buffer, buffer_f32, _value1);

    // param: _value2, type: Float32
    if (!is_numeric(_value2)) show_error($"{_GMFUNCTION_} :: _value2 expected number", true);
    buffer_write(__args_buffer, buffer_f32, _value2);

    // param: _value3, type: Float32
    if (!is_numeric(_value3)) show_error($"{_GMFUNCTION_} :: _value3 expected number", true);
    buffer_write(__args_buffer, buffer_f32, _value3);

    var _return_value = __id3d11_device_context_clear_unordered_access_view_float(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _depthStencilView
 * @param {Real} _clearFlags
 * @param {Real} _depth
 * @param {Real} _stencil
 * @returns {Bool} 
 */
function id3d11_device_context_clear_depth_stencil_view(_context, _depthStencilView, _clearFlags, _depth, _stencil)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _depthStencilView, type: UInt64
    if (!is_numeric(_depthStencilView)) show_error($"{_GMFUNCTION_} :: _depthStencilView expected number", true);
    buffer_write(__args_buffer, buffer_u64, _depthStencilView);

    // param: _clearFlags, type: UInt32
    if (!is_numeric(_clearFlags)) show_error($"{_GMFUNCTION_} :: _clearFlags expected number", true);
    buffer_write(__args_buffer, buffer_u32, _clearFlags);

    // param: _depth, type: Float32
    if (!is_numeric(_depth)) show_error($"{_GMFUNCTION_} :: _depth expected number", true);
    buffer_write(__args_buffer, buffer_f32, _depth);

    // param: _stencil, type: UInt32
    if (!is_numeric(_stencil)) show_error($"{_GMFUNCTION_} :: _stencil expected number", true);
    buffer_write(__args_buffer, buffer_u32, _stencil);

    var _return_value = __id3d11_device_context_clear_depth_stencil_view(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _shaderResourceView
 * @returns {Bool} 
 */
function id3d11_device_context_generate_mips(_context, _shaderResourceView)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _shaderResourceView, type: UInt64
    if (!is_numeric(_shaderResourceView)) show_error($"{_GMFUNCTION_} :: _shaderResourceView expected number", true);
    buffer_write(__args_buffer, buffer_u64, _shaderResourceView);

    var _return_value = __id3d11_device_context_generate_mips(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _resource
 * @param {Real} _minimumLod
 * @returns {Bool} 
 */
function id3d11_device_context_set_resource_min_lod(_context, _resource, _minimumLod)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    // param: _minimumLod, type: Float32
    if (!is_numeric(_minimumLod)) show_error($"{_GMFUNCTION_} :: _minimumLod expected number", true);
    buffer_write(__args_buffer, buffer_f32, _minimumLod);

    var _return_value = __id3d11_device_context_set_resource_min_lod(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _resource
 * @returns {Real} 
 */
function id3d11_device_context_get_resource_min_lod(_context, _resource)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _resource, type: UInt64
    if (!is_numeric(_resource)) show_error($"{_GMFUNCTION_} :: _resource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _resource);

    var _return_value = __id3d11_device_context_get_resource_min_lod(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _destinationResource
 * @param {Real} _destinationSubresource
 * @param {Real} _sourceResource
 * @param {Real} _sourceSubresource
 * @param {Real} _format
 * @returns {Bool} 
 */
function id3d11_device_context_resolve_subresource(_context, _destinationResource, _destinationSubresource, _sourceResource, _sourceSubresource, _format)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _destinationResource, type: UInt64
    if (!is_numeric(_destinationResource)) show_error($"{_GMFUNCTION_} :: _destinationResource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _destinationResource);

    // param: _destinationSubresource, type: UInt32
    if (!is_numeric(_destinationSubresource)) show_error($"{_GMFUNCTION_} :: _destinationSubresource expected number", true);
    buffer_write(__args_buffer, buffer_u32, _destinationSubresource);

    // param: _sourceResource, type: UInt64
    if (!is_numeric(_sourceResource)) show_error($"{_GMFUNCTION_} :: _sourceResource expected number", true);
    buffer_write(__args_buffer, buffer_u64, _sourceResource);

    // param: _sourceSubresource, type: UInt32
    if (!is_numeric(_sourceSubresource)) show_error($"{_GMFUNCTION_} :: _sourceSubresource expected number", true);
    buffer_write(__args_buffer, buffer_u32, _sourceSubresource);

    // param: _format, type: UInt32
    if (!is_numeric(_format)) show_error($"{_GMFUNCTION_} :: _format expected number", true);
    buffer_write(__args_buffer, buffer_u32, _format);

    var _return_value = __id3d11_device_context_resolve_subresource(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _inputLayout
 * @returns {Bool} 
 */
function id3d11_device_context_ia_set_input_layout(_context, _inputLayout)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _inputLayout, type: UInt64
    if (!is_numeric(_inputLayout)) show_error($"{_GMFUNCTION_} :: _inputLayout expected number", true);
    buffer_write(__args_buffer, buffer_u64, _inputLayout);

    var _return_value = __id3d11_device_context_ia_set_input_layout(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Real} 
 */
function id3d11_device_context_ia_get_input_layout(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ia_get_input_layout(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _context
 * @param {Enum.ID3D11PrimitiveTopology} _topology
 * @returns {Bool} 
 */
function id3d11_device_context_ia_set_primitive_topology(_context, _topology)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _topology, type: enum ID3D11PrimitiveTopology

    if (!is_numeric(_topology)) show_error($"{_GMFUNCTION_} :: _topology expected number", true);
    buffer_write(__args_buffer, buffer_u32, _topology);

    var _return_value = __id3d11_device_context_ia_set_primitive_topology(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Enum.ID3D11PrimitiveTopology} 
 */
function id3d11_device_context_ia_get_primitive_topology(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ia_get_primitive_topology(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u32);
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _state
 * @returns {Bool} 
 */
function id3d11_device_context_rs_set_state(_context, _state)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _state, type: UInt64
    if (!is_numeric(_state)) show_error($"{_GMFUNCTION_} :: _state expected number", true);
    buffer_write(__args_buffer, buffer_u64, _state);

    var _return_value = __id3d11_device_context_rs_set_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Real} 
 */
function id3d11_device_context_rs_get_state(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_rs_get_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _state
 * @param {Array[Real]} _blendFactor
 * @param {Real} _sampleMask
 * @returns {Bool} 
 */
function id3d11_device_context_om_set_blend_state(_context, _state, _blendFactor, _sampleMask)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _state, type: UInt64
    if (!is_numeric(_state)) show_error($"{_GMFUNCTION_} :: _state expected number", true);
    buffer_write(__args_buffer, buffer_u64, _state);

    // param: _blendFactor, type: Float32[]
    if (!is_array(_blendFactor)) show_error($"{_GMFUNCTION_} :: _blendFactor expected array", true);
    var _length = array_length(_blendFactor);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_blendFactor[_i])) show_error($"{_GMFUNCTION_} :: _blendFactor[_i] expected number", true);
        buffer_write(__args_buffer, buffer_f32, _blendFactor[_i]);
    }

    // param: _sampleMask, type: UInt32
    if (!is_numeric(_sampleMask)) show_error($"{_GMFUNCTION_} :: _sampleMask expected number", true);
    buffer_write(__args_buffer, buffer_u32, _sampleMask);

    var _return_value = __id3d11_device_context_om_set_blend_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11BlendStateBinding} 
 */
function id3d11_device_context_om_get_blend_state(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_om_get_blend_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11BlendStateBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _state
 * @param {Real} _stencilRef
 * @returns {Bool} 
 */
function id3d11_device_context_om_set_depth_stencil_state(_context, _state, _stencilRef)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _state, type: UInt64
    if (!is_numeric(_state)) show_error($"{_GMFUNCTION_} :: _state expected number", true);
    buffer_write(__args_buffer, buffer_u64, _state);

    // param: _stencilRef, type: UInt32
    if (!is_numeric(_stencilRef)) show_error($"{_GMFUNCTION_} :: _stencilRef expected number", true);
    buffer_write(__args_buffer, buffer_u32, _stencilRef);

    var _return_value = __id3d11_device_context_om_set_depth_stencil_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11DepthStencilStateBinding} 
 */
function id3d11_device_context_om_get_depth_stencil_state(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_om_get_depth_stencil_state(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11DepthStencilStateBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _predicate
 * @param {Bool} _predicateValue
 * @returns {Bool} 
 */
function id3d11_device_context_set_predication(_context, _predicate, _predicateValue)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _predicate, type: UInt64
    if (!is_numeric(_predicate)) show_error($"{_GMFUNCTION_} :: _predicate expected number", true);
    buffer_write(__args_buffer, buffer_u64, _predicate);

    // param: _predicateValue, type: Bool
    if (!is_bool(_predicateValue)) show_error($"{_GMFUNCTION_} :: _predicateValue expected bool", true);
    buffer_write(__args_buffer, buffer_bool, _predicateValue);

    var _return_value = __id3d11_device_context_set_predication(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11PredicationBinding} 
 */
function id3d11_device_context_get_predication(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_get_predication(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11PredicationBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Struct.ID3D11VertexBufferBinding]} _bindings
 * @returns {Bool} 
 */
function id3d11_device_context_ia_set_vertex_buffers(_context, _startSlot, _bindings)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _bindings, type: struct ID3D11VertexBufferBinding[]
    if (!is_array(_bindings)) show_error($"{_GMFUNCTION_} :: _bindings expected array", true);
    var _length = array_length(_bindings);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_bindings[_i].__uid != 2088290246) show_error($"{_GMFUNCTION_} :: _bindings[_i] expected ID3D11VertexBufferBinding", true);
        __ID3D11VertexBufferBinding_encode(_bindings[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    var _return_value = __id3d11_device_context_ia_set_vertex_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Struct.ID3D11VertexBufferBinding]} 
 */
function id3d11_device_context_ia_get_vertex_buffers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ia_get_vertex_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = __ID3D11VertexBufferBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _buffer
 * @param {Real} _format
 * @param {Real} _offset
 * @returns {Bool} 
 */
function id3d11_device_context_ia_set_index_buffer(_context, _buffer, _format, _offset)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _buffer, type: UInt64
    if (!is_numeric(_buffer)) show_error($"{_GMFUNCTION_} :: _buffer expected number", true);
    buffer_write(__args_buffer, buffer_u64, _buffer);

    // param: _format, type: UInt32
    if (!is_numeric(_format)) show_error($"{_GMFUNCTION_} :: _format expected number", true);
    buffer_write(__args_buffer, buffer_u32, _format);

    // param: _offset, type: UInt32
    if (!is_numeric(_offset)) show_error($"{_GMFUNCTION_} :: _offset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _offset);

    var _return_value = __id3d11_device_context_ia_set_index_buffer(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11IndexBufferBinding} 
 */
function id3d11_device_context_ia_get_index_buffer(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ia_get_index_buffer(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11IndexBufferBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Array[Struct.ID3D11Viewport]} _viewports
 * @returns {Bool} 
 */
function id3d11_device_context_rs_set_viewports(_context, _viewports)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _viewports, type: struct ID3D11Viewport[]
    if (!is_array(_viewports)) show_error($"{_GMFUNCTION_} :: _viewports expected array", true);
    var _length = array_length(_viewports);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_viewports[_i].__uid != 689095599) show_error($"{_GMFUNCTION_} :: _viewports[_i] expected ID3D11Viewport", true);
        __ID3D11Viewport_encode(_viewports[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    var _return_value = __id3d11_device_context_rs_set_viewports(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Array[Struct.ID3D11Viewport]} 
 */
function id3d11_device_context_rs_get_viewports(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_rs_get_viewports(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = __ID3D11Viewport_decode(__ret_buffer, buffer_tell(__ret_buffer));
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Array[Struct.ID3D11Rect]} _rects
 * @returns {Bool} 
 */
function id3d11_device_context_rs_set_scissor_rects(_context, _rects)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _rects, type: struct ID3D11Rect[]
    if (!is_array(_rects)) show_error($"{_GMFUNCTION_} :: _rects expected array", true);
    var _length = array_length(_rects);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (_rects[_i].__uid != 2780430747) show_error($"{_GMFUNCTION_} :: _rects[_i] expected ID3D11Rect", true);
        __ID3D11Rect_encode(_rects[_i], __args_buffer, buffer_tell(__args_buffer), _GMFUNCTION_);
    }

    var _return_value = __id3d11_device_context_rs_set_scissor_rects(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Array[Struct.ID3D11Rect]} 
 */
function id3d11_device_context_rs_get_scissor_rects(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_rs_get_scissor_rects(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = __ID3D11Rect_decode(__ret_buffer, buffer_tell(__ret_buffer));
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _buffers
 * @returns {Bool} 
 */
function id3d11_device_context_vs_set_constant_buffers(_context, _startSlot, _buffers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _buffers, type: UInt64[]
    if (!is_array(_buffers)) show_error($"{_GMFUNCTION_} :: _buffers expected array", true);
    var _length = array_length(_buffers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_buffers[_i])) show_error($"{_GMFUNCTION_} :: _buffers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _buffers[_i]);
    }

    var _return_value = __id3d11_device_context_vs_set_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_vs_get_constant_buffers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_vs_get_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _views
 * @returns {Bool} 
 */
function id3d11_device_context_vs_set_shader_resources(_context, _startSlot, _views)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _views, type: UInt64[]
    if (!is_array(_views)) show_error($"{_GMFUNCTION_} :: _views expected array", true);
    var _length = array_length(_views);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_views[_i])) show_error($"{_GMFUNCTION_} :: _views[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _views[_i]);
    }

    var _return_value = __id3d11_device_context_vs_set_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_vs_get_shader_resources(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_vs_get_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _samplers
 * @returns {Bool} 
 */
function id3d11_device_context_vs_set_samplers(_context, _startSlot, _samplers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _samplers, type: UInt64[]
    if (!is_array(_samplers)) show_error($"{_GMFUNCTION_} :: _samplers expected array", true);
    var _length = array_length(_samplers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_samplers[_i])) show_error($"{_GMFUNCTION_} :: _samplers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _samplers[_i]);
    }

    var _return_value = __id3d11_device_context_vs_set_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_vs_get_samplers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_vs_get_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _buffers
 * @returns {Bool} 
 */
function id3d11_device_context_hs_set_constant_buffers(_context, _startSlot, _buffers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _buffers, type: UInt64[]
    if (!is_array(_buffers)) show_error($"{_GMFUNCTION_} :: _buffers expected array", true);
    var _length = array_length(_buffers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_buffers[_i])) show_error($"{_GMFUNCTION_} :: _buffers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _buffers[_i]);
    }

    var _return_value = __id3d11_device_context_hs_set_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_hs_get_constant_buffers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_hs_get_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _views
 * @returns {Bool} 
 */
function id3d11_device_context_hs_set_shader_resources(_context, _startSlot, _views)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _views, type: UInt64[]
    if (!is_array(_views)) show_error($"{_GMFUNCTION_} :: _views expected array", true);
    var _length = array_length(_views);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_views[_i])) show_error($"{_GMFUNCTION_} :: _views[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _views[_i]);
    }

    var _return_value = __id3d11_device_context_hs_set_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_hs_get_shader_resources(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_hs_get_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _samplers
 * @returns {Bool} 
 */
function id3d11_device_context_hs_set_samplers(_context, _startSlot, _samplers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _samplers, type: UInt64[]
    if (!is_array(_samplers)) show_error($"{_GMFUNCTION_} :: _samplers expected array", true);
    var _length = array_length(_samplers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_samplers[_i])) show_error($"{_GMFUNCTION_} :: _samplers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _samplers[_i]);
    }

    var _return_value = __id3d11_device_context_hs_set_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_hs_get_samplers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_hs_get_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _buffers
 * @returns {Bool} 
 */
function id3d11_device_context_ds_set_constant_buffers(_context, _startSlot, _buffers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _buffers, type: UInt64[]
    if (!is_array(_buffers)) show_error($"{_GMFUNCTION_} :: _buffers expected array", true);
    var _length = array_length(_buffers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_buffers[_i])) show_error($"{_GMFUNCTION_} :: _buffers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _buffers[_i]);
    }

    var _return_value = __id3d11_device_context_ds_set_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_ds_get_constant_buffers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ds_get_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _views
 * @returns {Bool} 
 */
function id3d11_device_context_ds_set_shader_resources(_context, _startSlot, _views)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _views, type: UInt64[]
    if (!is_array(_views)) show_error($"{_GMFUNCTION_} :: _views expected array", true);
    var _length = array_length(_views);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_views[_i])) show_error($"{_GMFUNCTION_} :: _views[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _views[_i]);
    }

    var _return_value = __id3d11_device_context_ds_set_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_ds_get_shader_resources(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ds_get_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _samplers
 * @returns {Bool} 
 */
function id3d11_device_context_ds_set_samplers(_context, _startSlot, _samplers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _samplers, type: UInt64[]
    if (!is_array(_samplers)) show_error($"{_GMFUNCTION_} :: _samplers expected array", true);
    var _length = array_length(_samplers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_samplers[_i])) show_error($"{_GMFUNCTION_} :: _samplers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _samplers[_i]);
    }

    var _return_value = __id3d11_device_context_ds_set_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_ds_get_samplers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ds_get_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _buffers
 * @returns {Bool} 
 */
function id3d11_device_context_gs_set_constant_buffers(_context, _startSlot, _buffers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _buffers, type: UInt64[]
    if (!is_array(_buffers)) show_error($"{_GMFUNCTION_} :: _buffers expected array", true);
    var _length = array_length(_buffers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_buffers[_i])) show_error($"{_GMFUNCTION_} :: _buffers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _buffers[_i]);
    }

    var _return_value = __id3d11_device_context_gs_set_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_gs_get_constant_buffers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_gs_get_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _views
 * @returns {Bool} 
 */
function id3d11_device_context_gs_set_shader_resources(_context, _startSlot, _views)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _views, type: UInt64[]
    if (!is_array(_views)) show_error($"{_GMFUNCTION_} :: _views expected array", true);
    var _length = array_length(_views);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_views[_i])) show_error($"{_GMFUNCTION_} :: _views[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _views[_i]);
    }

    var _return_value = __id3d11_device_context_gs_set_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_gs_get_shader_resources(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_gs_get_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _samplers
 * @returns {Bool} 
 */
function id3d11_device_context_gs_set_samplers(_context, _startSlot, _samplers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _samplers, type: UInt64[]
    if (!is_array(_samplers)) show_error($"{_GMFUNCTION_} :: _samplers expected array", true);
    var _length = array_length(_samplers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_samplers[_i])) show_error($"{_GMFUNCTION_} :: _samplers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _samplers[_i]);
    }

    var _return_value = __id3d11_device_context_gs_set_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_gs_get_samplers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_gs_get_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _buffers
 * @returns {Bool} 
 */
function id3d11_device_context_ps_set_constant_buffers(_context, _startSlot, _buffers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _buffers, type: UInt64[]
    if (!is_array(_buffers)) show_error($"{_GMFUNCTION_} :: _buffers expected array", true);
    var _length = array_length(_buffers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_buffers[_i])) show_error($"{_GMFUNCTION_} :: _buffers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _buffers[_i]);
    }

    var _return_value = __id3d11_device_context_ps_set_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_ps_get_constant_buffers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ps_get_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _views
 * @returns {Bool} 
 */
function id3d11_device_context_ps_set_shader_resources(_context, _startSlot, _views)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _views, type: UInt64[]
    if (!is_array(_views)) show_error($"{_GMFUNCTION_} :: _views expected array", true);
    var _length = array_length(_views);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_views[_i])) show_error($"{_GMFUNCTION_} :: _views[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _views[_i]);
    }

    var _return_value = __id3d11_device_context_ps_set_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_ps_get_shader_resources(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ps_get_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _samplers
 * @returns {Bool} 
 */
function id3d11_device_context_ps_set_samplers(_context, _startSlot, _samplers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _samplers, type: UInt64[]
    if (!is_array(_samplers)) show_error($"{_GMFUNCTION_} :: _samplers expected array", true);
    var _length = array_length(_samplers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_samplers[_i])) show_error($"{_GMFUNCTION_} :: _samplers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _samplers[_i]);
    }

    var _return_value = __id3d11_device_context_ps_set_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_ps_get_samplers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ps_get_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _buffers
 * @returns {Bool} 
 */
function id3d11_device_context_cs_set_constant_buffers(_context, _startSlot, _buffers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _buffers, type: UInt64[]
    if (!is_array(_buffers)) show_error($"{_GMFUNCTION_} :: _buffers expected array", true);
    var _length = array_length(_buffers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_buffers[_i])) show_error($"{_GMFUNCTION_} :: _buffers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _buffers[_i]);
    }

    var _return_value = __id3d11_device_context_cs_set_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_cs_get_constant_buffers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_cs_get_constant_buffers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _views
 * @returns {Bool} 
 */
function id3d11_device_context_cs_set_shader_resources(_context, _startSlot, _views)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _views, type: UInt64[]
    if (!is_array(_views)) show_error($"{_GMFUNCTION_} :: _views expected array", true);
    var _length = array_length(_views);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_views[_i])) show_error($"{_GMFUNCTION_} :: _views[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _views[_i]);
    }

    var _return_value = __id3d11_device_context_cs_set_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_cs_get_shader_resources(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_cs_get_shader_resources(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Array[Real]} _samplers
 * @returns {Bool} 
 */
function id3d11_device_context_cs_set_samplers(_context, _startSlot, _samplers)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _samplers, type: UInt64[]
    if (!is_array(_samplers)) show_error($"{_GMFUNCTION_} :: _samplers expected array", true);
    var _length = array_length(_samplers);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_samplers[_i])) show_error($"{_GMFUNCTION_} :: _samplers[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _samplers[_i]);
    }

    var _return_value = __id3d11_device_context_cs_set_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @param {Real} _startSlot
 * @param {Real} _count
 * @returns {Array[Real]} 
 */
function id3d11_device_context_cs_get_samplers(_context, _startSlot, _count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _startSlot, type: UInt32
    if (!is_numeric(_startSlot)) show_error($"{_GMFUNCTION_} :: _startSlot expected number", true);
    buffer_write(__args_buffer, buffer_u32, _startSlot);

    // param: _count, type: UInt32
    if (!is_numeric(_count)) show_error($"{_GMFUNCTION_} :: _count expected number", true);
    buffer_write(__args_buffer, buffer_u32, _count);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_cs_get_samplers(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    var _length = buffer_read(__ret_buffer, buffer_u32);
    _result = array_create(_length);
    for (var _i = 0; _i < _length; ++_i)
    {
        _result[_i] = buffer_read(__ret_buffer, buffer_u64);
    }
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _shader
 * @param {Array[Real]} _classInstances
 * @returns {Bool} 
 */
function id3d11_device_context_vs_set_shader(_context, _shader, _classInstances)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _shader, type: UInt64
    if (!is_numeric(_shader)) show_error($"{_GMFUNCTION_} :: _shader expected number", true);
    buffer_write(__args_buffer, buffer_u64, _shader);

    // param: _classInstances, type: UInt64[]
    if (!is_array(_classInstances)) show_error($"{_GMFUNCTION_} :: _classInstances expected array", true);
    var _length = array_length(_classInstances);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_classInstances[_i])) show_error($"{_GMFUNCTION_} :: _classInstances[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _classInstances[_i]);
    }

    var _return_value = __id3d11_device_context_vs_set_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11ShaderBinding} 
 */
function id3d11_device_context_vs_get_shader(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_vs_get_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _shader
 * @param {Array[Real]} _classInstances
 * @returns {Bool} 
 */
function id3d11_device_context_hs_set_shader(_context, _shader, _classInstances)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _shader, type: UInt64
    if (!is_numeric(_shader)) show_error($"{_GMFUNCTION_} :: _shader expected number", true);
    buffer_write(__args_buffer, buffer_u64, _shader);

    // param: _classInstances, type: UInt64[]
    if (!is_array(_classInstances)) show_error($"{_GMFUNCTION_} :: _classInstances expected array", true);
    var _length = array_length(_classInstances);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_classInstances[_i])) show_error($"{_GMFUNCTION_} :: _classInstances[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _classInstances[_i]);
    }

    var _return_value = __id3d11_device_context_hs_set_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11ShaderBinding} 
 */
function id3d11_device_context_hs_get_shader(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_hs_get_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _shader
 * @param {Array[Real]} _classInstances
 * @returns {Bool} 
 */
function id3d11_device_context_ds_set_shader(_context, _shader, _classInstances)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _shader, type: UInt64
    if (!is_numeric(_shader)) show_error($"{_GMFUNCTION_} :: _shader expected number", true);
    buffer_write(__args_buffer, buffer_u64, _shader);

    // param: _classInstances, type: UInt64[]
    if (!is_array(_classInstances)) show_error($"{_GMFUNCTION_} :: _classInstances expected array", true);
    var _length = array_length(_classInstances);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_classInstances[_i])) show_error($"{_GMFUNCTION_} :: _classInstances[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _classInstances[_i]);
    }

    var _return_value = __id3d11_device_context_ds_set_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11ShaderBinding} 
 */
function id3d11_device_context_ds_get_shader(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ds_get_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _shader
 * @param {Array[Real]} _classInstances
 * @returns {Bool} 
 */
function id3d11_device_context_gs_set_shader(_context, _shader, _classInstances)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _shader, type: UInt64
    if (!is_numeric(_shader)) show_error($"{_GMFUNCTION_} :: _shader expected number", true);
    buffer_write(__args_buffer, buffer_u64, _shader);

    // param: _classInstances, type: UInt64[]
    if (!is_array(_classInstances)) show_error($"{_GMFUNCTION_} :: _classInstances expected array", true);
    var _length = array_length(_classInstances);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_classInstances[_i])) show_error($"{_GMFUNCTION_} :: _classInstances[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _classInstances[_i]);
    }

    var _return_value = __id3d11_device_context_gs_set_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11ShaderBinding} 
 */
function id3d11_device_context_gs_get_shader(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_gs_get_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _shader
 * @param {Array[Real]} _classInstances
 * @returns {Bool} 
 */
function id3d11_device_context_ps_set_shader(_context, _shader, _classInstances)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _shader, type: UInt64
    if (!is_numeric(_shader)) show_error($"{_GMFUNCTION_} :: _shader expected number", true);
    buffer_write(__args_buffer, buffer_u64, _shader);

    // param: _classInstances, type: UInt64[]
    if (!is_array(_classInstances)) show_error($"{_GMFUNCTION_} :: _classInstances expected array", true);
    var _length = array_length(_classInstances);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_classInstances[_i])) show_error($"{_GMFUNCTION_} :: _classInstances[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _classInstances[_i]);
    }

    var _return_value = __id3d11_device_context_ps_set_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11ShaderBinding} 
 */
function id3d11_device_context_ps_get_shader(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_ps_get_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _context
 * @param {Real} _shader
 * @param {Array[Real]} _classInstances
 * @returns {Bool} 
 */
function id3d11_device_context_cs_set_shader(_context, _shader, _classInstances)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    // param: _shader, type: UInt64
    if (!is_numeric(_shader)) show_error($"{_GMFUNCTION_} :: _shader expected number", true);
    buffer_write(__args_buffer, buffer_u64, _shader);

    // param: _classInstances, type: UInt64[]
    if (!is_array(_classInstances)) show_error($"{_GMFUNCTION_} :: _classInstances expected array", true);
    var _length = array_length(_classInstances);
    buffer_write(__args_buffer, buffer_u32, _length);
    for (var _i = 0; _i < _length; ++_i)
    {
        if (!is_numeric(_classInstances[_i])) show_error($"{_GMFUNCTION_} :: _classInstances[_i] expected number", true);
        buffer_write(__args_buffer, buffer_u64, _classInstances[_i]);
    }

    var _return_value = __id3d11_device_context_cs_set_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _context
 * @returns {Struct.ID3D11ShaderBinding} 
 */
function id3d11_device_context_cs_get_shader(_context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _context, type: UInt64
    if (!is_numeric(_context)) show_error($"{_GMFUNCTION_} :: _context expected number", true);
    buffer_write(__args_buffer, buffer_u64, _context);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_device_context_cs_get_shader(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ShaderBinding_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _linkage
 * @param {String} _classInstanceName
 * @param {Real} _instanceIndex
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_class_linkage_get_class_instance(_linkage, _classInstanceName, _instanceIndex)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _linkage, type: UInt64
    if (!is_numeric(_linkage)) show_error($"{_GMFUNCTION_} :: _linkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _linkage);

    // param: _classInstanceName, type: String
    if (!is_string(_classInstanceName)) show_error($"{_GMFUNCTION_} :: _classInstanceName expected string", true);
    buffer_write(__args_buffer, buffer_u32, string_byte_length(_classInstanceName));
    buffer_write(__args_buffer, buffer_string, _classInstanceName);

    // param: _instanceIndex, type: UInt32
    if (!is_numeric(_instanceIndex)) show_error($"{_GMFUNCTION_} :: _instanceIndex expected number", true);
    buffer_write(__args_buffer, buffer_u32, _instanceIndex);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_class_linkage_get_class_instance(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _linkage
 * @param {String} _classTypeName
 * @param {Real} _constantBufferOffset
 * @param {Real} _constantVectorOffset
 * @param {Real} _textureOffset
 * @param {Real} _samplerOffset
 * @returns {Struct.ID3D11CreateHandleResult} 
 */
function id3d11_class_linkage_create_class_instance(_linkage, _classTypeName, _constantBufferOffset, _constantVectorOffset, _textureOffset, _samplerOffset)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _linkage, type: UInt64
    if (!is_numeric(_linkage)) show_error($"{_GMFUNCTION_} :: _linkage expected number", true);
    buffer_write(__args_buffer, buffer_u64, _linkage);

    // param: _classTypeName, type: String
    if (!is_string(_classTypeName)) show_error($"{_GMFUNCTION_} :: _classTypeName expected string", true);
    buffer_write(__args_buffer, buffer_u32, string_byte_length(_classTypeName));
    buffer_write(__args_buffer, buffer_string, _classTypeName);

    // param: _constantBufferOffset, type: UInt32
    if (!is_numeric(_constantBufferOffset)) show_error($"{_GMFUNCTION_} :: _constantBufferOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _constantBufferOffset);

    // param: _constantVectorOffset, type: UInt32
    if (!is_numeric(_constantVectorOffset)) show_error($"{_GMFUNCTION_} :: _constantVectorOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _constantVectorOffset);

    // param: _textureOffset, type: UInt32
    if (!is_numeric(_textureOffset)) show_error($"{_GMFUNCTION_} :: _textureOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _textureOffset);

    // param: _samplerOffset, type: UInt32
    if (!is_numeric(_samplerOffset)) show_error($"{_GMFUNCTION_} :: _samplerOffset expected number", true);
    buffer_write(__args_buffer, buffer_u32, _samplerOffset);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_class_linkage_create_class_instance(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11CreateHandleResult_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _instance
 * @returns {Real} 
 */
function id3d11_class_instance_get_class_linkage(_instance)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _instance, type: UInt64
    if (!is_numeric(_instance)) show_error($"{_GMFUNCTION_} :: _instance expected number", true);
    buffer_write(__args_buffer, buffer_u64, _instance);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_class_instance_get_class_linkage(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = buffer_read(__ret_buffer, buffer_u64);
    return _result;
}

/**
 * @param {Real} _instance
 * @returns {Struct.ID3D11ClassInstanceDesc} 
 */
function id3d11_class_instance_get_desc(_instance)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _instance, type: UInt64
    if (!is_numeric(_instance)) show_error($"{_GMFUNCTION_} :: _instance expected number", true);
    buffer_write(__args_buffer, buffer_u64, _instance);

    var __ret_buffer = __ext_core_get_ret_buffer();

    var _return_value = __id3d11_class_instance_get_desc(buffer_get_address(__args_buffer), buffer_tell(__args_buffer), buffer_get_address(__ret_buffer), buffer_get_size(__ret_buffer));

    var _result = undefined;
    _result = __ID3D11ClassInstanceDesc_decode(__ret_buffer, buffer_tell(__ret_buffer));
    return _result;
}

/**
 * @param {Real} _instance
 * @returns {String} 
 */
function id3d11_class_instance_get_instance_name(_instance)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _instance, type: UInt64
    if (!is_numeric(_instance)) show_error($"{_GMFUNCTION_} :: _instance expected number", true);
    buffer_write(__args_buffer, buffer_u64, _instance);

    var _return_value = __id3d11_class_instance_get_instance_name(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Real} _instance
 * @returns {String} 
 */
function id3d11_class_instance_get_type_name(_instance)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _instance, type: UInt64
    if (!is_numeric(_instance)) show_error($"{_GMFUNCTION_} :: _instance expected number", true);
    buffer_write(__args_buffer, buffer_u64, _instance);

    var _return_value = __id3d11_class_instance_get_type_name(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/// @ignore
function __ID3D11_get_decoders()
{
    static __decoders = [
        __ID3D11Version_decode,
        __ID3D11FormatSupportResult_decode,
        __ID3D11MultisampleQualityResult_decode,
        __ID3D11CounterInfo_decode,
        __ID3D11BufferDesc_decode,
        __ID3D11SubresourceData_decode,
        __ID3D11Texture1DDesc_decode,
        __ID3D11Texture2DDesc_decode,
        __ID3D11Texture3DDesc_decode,
        __ID3D11ShaderResourceViewDesc_decode,
        __ID3D11RenderTargetViewDesc_decode,
        __ID3D11DepthStencilViewDesc_decode,
        __ID3D11UnorderedAccessViewDesc_decode,
        __ID3D11InputElementDesc_decode,
        __ID3D11StreamOutputDeclarationEntry_decode,
        __ID3D11ShaderCompileResult_decode,
        __ID3D11SamplerDesc_decode,
        __ID3D11RasterizerDesc_decode,
        __ID3D11RenderTargetBlendDesc_decode,
        __ID3D11DepthStencilOpDesc_decode,
        __ID3D11QueryDesc_decode,
        __ID3D11CounterDesc_decode,
        __ID3D11CheckCounterResult_decode,
        __ID3D11BlendStateBinding_decode,
        __ID3D11DepthStencilStateBinding_decode,
        __ID3D11PredicationBinding_decode,
        __ID3D11VertexBufferBinding_decode,
        __ID3D11IndexBufferBinding_decode,
        __ID3D11Viewport_decode,
        __ID3D11Rect_decode,
        __ID3D11Box_decode,
        __ID3D11ShaderBinding_decode,
        __ID3D11ClassInstanceDesc_decode,
        __ID3D11CreateHandleResult_decode,
        __ID3D11BlendDesc_decode,
        __ID3D11DepthStencilDesc_decode
    ];
    return __decoders;
}

