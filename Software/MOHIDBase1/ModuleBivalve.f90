    !-----------------------------------------------------------------------------------
    !        IST/MARETEC, Water Modelling Group, Mohid modelling system
    !-----------------------------------------------------------------------------------
    !
    ! TITLE         : Mohid Model
    ! PROJECT       : Mohid Base 1
    ! MODULE        : Bivalve
    ! URL           : http://www.mohid.com
    ! AFFILIATION   : IST/MARETEC, Marine Modelling Group
    ! DATE          : 5 Out 2012
    ! REVISION      : Sofia Saraiva
    ! DESCRIPTION   : Individual Based Population (or individual) model for one/several bivalve
    !                 species following DED theory 
    !
    !-----------------------------------------------------------------------------------
    Module ModuleBivalve

    use ModuleGlobalData
    use ModuleEnterData
    use ModuleTime
    use ifport

    implicit none

    private 

    !Subroutines---------------------------------------------------------------------

    !Constructor
    public  ::      ConstructBivalve
    private ::          AllocateInstance
    private ::          ReadDataBivalve
    private ::              ConstructGlobalVariables
    private ::              ConstructSpecies
    private ::                  AddSpecies
    private ::                  ConstructSpeciesParameters
    private ::                      ConstructSpeciesComposition
    private ::                      ConstructIndividualParameters
    private ::                      ConstructParticles
    private ::                          AddParticles
    private ::                          ConstructParticlesParameters
    private ::                      ConstructPredator
    private ::                          AddPredator
    private ::                          ConstructPredatorParameters
    private ::                  ConstructCohort
    private ::                      AddCohort
    private ::                      ConstructCohortOutput
    private ::              ConstructOutputs
    private ::          PropertyIndexNumber
    private ::          ConstructPropertyList
    private ::          KillEnterData    

    !Selector
    public  ::      GetBivalvePropertyList
    public  ::      GetDTBivalve
    public  ::      GetBivalveSize
    public  ::      GetBivalvePropIndex
    public  ::      GetBivalveListDeadIDS
    public  ::      GetBivalveNewborns
    public  ::      GetBivalveNewBornParameters
    public  ::      GetBivalveOtherParameters
    public  ::      UnGetBivalve
    public  ::      SearchPropIndex

    !Modifier
    public  ::      ModifyBivalve
    public  ::          AllocateAndInitializeByTimeStep
    private ::          ComputeBivalve
    private ::              AllocateAndInitializeByIndex
    private ::              ComputeIndividualProcesses
    private ::                  ComputeChemicalIndices
    private ::                  ComputeAuxiliarParameters
    private ::                  ComputeBivalveCondition
    private ::                  ComputeFeedingProcesses
    private ::                      ComputeSimpleFiltration
    private ::                      ComputeComplexFiltration
    private ::                  ComputeSomaticMaintenance
    private ::                  ComputeMobilization
    private ::                  ComputeReservesDynamics
    private ::                  ComputeStructureDynamics
    private ::                  ComputeMaturity
    private ::                  ComputeLengthAgeDynamics
    private ::                  ComputeSpawning
    private ::                  ComputeReproductionDynamics
    private ::                  ComputeInorganicFluxes
    private ::                  ImposeCohortDeath
    private ::              ComputeNaturalMortality
    private ::              ComputePredation
    private ::                  ComputePredationByPredator
    private ::              ComputePopulationVariables
    private ::              WriteOutput
    private ::                  WriteSizeDistribution
    private ::                  WriteMassBalance
    private ::              UpdateCohortState
    private ::              RestoreUnits
    private ::          UpdateListDeadAndNewBornIDs
    public  ::          UpdateBivalvePropertyList
    !Destructor
    public  ::      KillBivalve
    private ::          WriteTestingFile           
    private ::      DeAllocateInstance
    private ::      CloseFiles
    !Management
    private ::      Ready
    private ::      LocateObjBivalve 

    !Interfaces---------------------------------------------------------------------
    private ::       UnGetBivalve1D_I
    private ::       UnGetBivalve2D_R4
    interface        UnGetBivalve
    module procedure UnGetBivalve1D_I
    module procedure UnGetBivalve2D_R4
    end interface    UnGetBivalve

    !Types--------------------------------------------------------------------------
    type     T_ExternalVar
        real,    pointer, dimension(:  )  :: Salinity    
        real,    pointer, dimension(:  )  :: Temperature
        real,    pointer, dimension(:,:)  :: Mass               !g/m3
        integer, pointer, dimension(:  )  :: OpenPoints
        real(8), pointer, dimension(:  )  :: CellVolume         !m3
        real,    pointer, dimension(:  )  :: CellArea           !m2
    end type T_ExternalVar

    type     T_ComputeOptions
        logical                           :: Nitrogen           = .false.
        logical                           :: Phosphorus         = .false.
        logical                           :: SimpleFiltration   = .false.
        logical                           :: CorrectFiltration  = .true.
        logical                           :: MassBalance        = .false.
        character(len=StringLength)       :: PelagicModel
    end type T_ComputeOptions 


    type      T_PropIndex     
        !Sediments             
        integer                           :: sediments             = null_int   !Cohesive sediments
        !Nitrogen                             
        integer                           :: AM                    = null_int
        integer                           :: PON                   = null_int   !Particulate Organic Nitrogen
        !Phosphorus                           
        integer                           :: IP                    = null_int   !Inorganic Phosphorus or Phosphate 
        integer                           :: POP                   = null_int   !Particulate Organic Phosphorus
        !Carbon 
        integer                           :: POC                   = null_int   !Particulate Organic Carbon
        integer                           :: CarbonDioxide         = null_int   !Carbon Dioxide 
        !Oxygen 
        integer                           :: Oxygen                = null_int
        !Silica                             
        integer                           :: BioSilica             = null_int
        integer                           :: DissSilica            = null_int
        !Food  
        integer                           :: phyto                 = null_int
        integer                           :: diatoms               = null_int
        integer                           :: zoo                   = null_int
        integer                           :: ciliate               = null_int
        integer                           :: bacteria              = null_int
        integer                           :: silica                = null_int

        integer                           :: DiatomsC              = null_int
        integer                           :: DiatomsN              = null_int
        integer                           :: DiatomsP              = null_int
        integer                           :: DiatomsChl            = null_int
        integer                           :: DiatomsSi             = null_int
        integer                           :: Mix_FlagellateC       = null_int
        integer                           :: Mix_FlagellateN       = null_int
        integer                           :: Mix_FlagellateP       = null_int
        integer                           :: Mix_FlagellateChl     = null_int
        integer                           :: PicoalgaeC            = null_int
        integer                           :: PicoalgaeN            = null_int
        integer                           :: PicoalgaeP            = null_int
        integer                           :: PicoalgaeChl          = null_int
        integer                           :: FlagellateC           = null_int
        integer                           :: FlagellateN           = null_int
        integer                           :: FlagellateP           = null_int
        integer                           :: FlagellateChl         = null_int
        integer                           :: MicrozooplanktonC     = null_int
        integer                           :: MicrozooplanktonN     = null_int
        integer                           :: MicrozooplanktonP     = null_int
        integer                           :: Het_NanoflagellateC   = null_int
        integer                           :: Het_NanoflagellateN   = null_int
        integer                           :: Het_NanoflagellateP   = null_int
        integer                           :: MesozooplanktonC      = null_int
        integer                           :: MesozooplanktonN      = null_int
        integer                           :: MesozooplanktonP      = null_int
        integer                           :: Het_BacteriaC         = null_int
        integer                           :: Het_BacteriaN         = null_int
        integer                           :: Het_BacteriaP         = null_int
        integer                           :: Shrimp                = null_int
        integer                           :: Crab                  = null_int
        integer                           :: OysterCatcher         = null_int
        integer                           :: EiderDuck             = null_int
        integer                           :: HerringGull           = null_int
    end type T_PropIndex  

    type     T_ID         
        integer                           :: ID, IDNumber
        character(len=StringLength)       :: Name   
        character(len=StringLength)       :: Description          
    end type T_ID         

    type     T_Composition
        real                              :: nC   = FillValueReal   !molC/molC, chemical index of carbon = 1
        real                              :: nH   = FillValueReal   !molH/molC, chemical index of hydrogen
        real                              :: nO   = FillValueReal   !molO/molC, chemical index of oxygen
        real                              :: nN   = FillValueReal   !molN/molC, chemical index of nitrogen
        real                              :: nP   = FillValueReal   !molP/molC, chemical index of phosphorus
    end type T_Composition          

    type     T_Ratios 
        real                             :: HC_Ratio     = FillValueReal   !Actual Ratio H/C [mgH/mgC]
        real                             :: OC_Ratio     = FillValueReal   !Actual Ratio O/C [mgO/mgC]
        real                             :: NC_Ratio     = FillValueReal   !Actual Ratio N/C [mgN/mgC]
        real                             :: PC_Ratio     = FillValueReal   !Actual Ratio P/C [mgP/mgC]
        real                             :: ChlC_Ratio   = FillValueReal   !Actual Ratio P/C [mgP/mgC]
        real                             :: SiC_Ratio    = FillValueReal   !Actual Ratio P/C [mgP/mgC]
    end type T_Ratios 

    type     T_SpeciesComposition       
        type (T_Composition  )           :: ReservesComposition  
        type (T_Composition  )           :: StructureComposition
    end type T_SpeciesComposition

    type     T_StateIndex      
        integer                          :: M_V      = null_int !molC (struc), structure biomass
        integer                          :: M_E      = null_int !molC (reser), reserves biomass
        integer                          :: M_H      = null_int !molC (reser), maturity
        integer                          :: M_R      = null_int !molC (reser), reproduction buffer
        integer                          :: L        = null_int !cm, bivalve real length
        integer                          :: Age      = null_int !days, bivalve age
        integer                          :: Number   = null_int !#, number of organims in the cohort
    end type T_StateIndex 

    type    T_IndividualParameters
        real                             :: Tref              = FillValueReal !K, Rate Temperature reference
        real                             :: TA                = FillValueReal !K, Arrhenius Temp
        real                             :: TL                = FillValueReal !K, Lower Boundary tolerance range
        real                             :: TH                = FillValueReal !K, Upper Boundary tolerance range
        real                             :: TAL               = FillValueReal !K, Arrhenius lower boundary
        real                             :: TAH               = FillValueReal !K, Arrhenius upper boundary
        real                             :: F_FIX             = FillValueReal !adim, constant food density parameter
        real                             :: PAM_FIX           = FillValueReal !Jd-1cm-2, bivalve sur-spec assimilation rate
        real                             :: delta_M           = FillValueReal !cm(volumetric)/cm(real), shape coefficient
        real                             :: LifeSpan          = FillValueReal !years, max life span
        real                             :: m_natural         = FillValueReal !/d, constant natural mortality rate
        real                             :: m_spat            = FillValueReal !/d, constant natural mortality rate
        real                             :: v_cond            = FillValueReal !cm/d, energy conductance
        real                             :: kappa             = FillValueReal !adim, allocation fraction to growth/SomMaintenace
        real                             :: kap_R             = FillValueReal !adim, reproduction efficiency
        real                             :: pM                = FillValueReal !J/(d.cm3), volume specific somatic maintenace
        real                             :: EG                = FillValueReal !J/cm3(volumetric), energy costs for structure
        real                             :: EHb               = FillValueReal !J, maturity threshold for birth
        real                             :: EHp               = FillValueReal !J, maturity threshold for puberty
        real                             :: Crm               = FillValueReal !m3/d.cm2, maximum clearance rate
        real                             :: JX1Fm             = FillValueReal !molC/(d.cm2),max surf area-specific filt algae
        real                             :: JX0Fm             = FillValueReal !g/(d.cm2),max surf area-specific filt for inorgmat
        real                             :: ro_X1             = FillValueReal !adim, binding  probability for algae
        real                             :: ro_X0             = FillValueReal !adim, binding  probability for inorganic material        
        real                             :: JX1Im             = FillValueReal !molC/d, max surf area-spec ing rate for algae
        real                             :: JX0Im             = FillValueReal !molC/d, max surf area-spec ing rate for inorg mat
        real                             :: YEX               = FillValueReal !molCE/molCX, yield coef of reser in algae struc       
        real                             :: GSR_MIN           = FillValueReal !molCE/molCV, min GSR in the organism
        real                             :: GSR_SPAWN         = FillValueReal !molCE/molCV, gonado-somatic ratio to spawn
        real                             :: T_SPAWN           = FillValueReal !oC, minimum temperature for spawning
        real                             :: MIN_SPAWN_TIME    = FillValueReal !d, minimum time interval between spawning events
        real                             :: ME_0              = FillValueReal !molC, reserves in an embryo at optimal food
        real                             :: MEb               = FillValueReal !molC, reserves in a new born at optimal food
        real                             :: MVb               = FillValueReal !molC, structure in a new born at optimal food
        real                             :: MHb               = FillValueReal !molC, maturity in a new born at optimal food
        real                             :: Lb                = FillValueReal !molC, length in a new born at optimal food
        real                             :: d_V               = FillValueReal !g(dw)/cm3, density of  structure
        real                             :: mu_E              = FillValueReal !J/molC(reser), chemical potential of reserves          
        integer                          :: SIMPLE_ASSI       = null_int      !1/0,Compute simple assimilation? 
        integer                          :: SIMPLE_TEMP       = null_int      !1/0,Compute simple temperature correction factor?
    end type T_IndividualParameters          

    type     T_AuxiliarParameters       
        real                             :: C_AtomicMass      = 12            !mgC/molC
        real                             :: H_AtomicMass      = 1             !mgH/molH
        real                             :: O_AtomicMass      = 16            !mgO/molO
        real                             :: N_AtomicMass      = 14            !mgN/molN
        real                             :: P_AtomicMass      = 31            !mgP/molP
        real                             :: TempCorrection    = FillValueReal !adim, temperature correction factor
        real                             :: WE                = FillValueReal !gDW/molC, AFDW to carbonV convertion
        real                             :: WV                = FillValueReal !gDW/molC, AFDW to carbonE convertion
        real                             :: Mv                = FillValueReal !molC(struc)/cm3, volume specific struc mass
        real                             :: MHb               = FillValueReal !molC, maturity threshold for birth
        real                             :: MHp               = FillValueReal !molC, maturity threshold for puberty
        real                             :: y_VE              = FillValueReal !molCV/molCE,yield coefficient of struc on reser
        real                             :: kM                = FillValueReal !/d, somatic maintenace rate coefficient
        real                             :: kJ                = FillValueReal !/d, maturity maintenace rate coefficient
        real                             :: Lm                = FillValueReal !cm, maximum length of the species
    end type T_AuxiliarParameters 

    type     T_BivalveCondition       
        real                             :: Vol               = FillValueReal !cm3, volumetric length
        real                             :: E                 = FillValueReal !molC(reser)/cm3, reserve density
        real                             :: GSR               = FillValueReal !molC(reser)/molC(total), gonado-somatic ratio
        real                             :: DW                = FillValueReal !g(dw), organism total dry weight
        real                             :: TotalmolC         = FillValueReal !molC, organism total molC
        real                             :: TotalmolN         = FillValueReal !molN, organism total molN
        real                             :: TotalmolP         = FillValueReal !molP, organism total molP
    end type T_BivalveCondition 

    type     T_ByElement          
        real                             :: C    = FillValueReal  !molC/d
        real                             :: H    = FillValueReal  !molH/d
        real                             :: O    = FillValueReal  !molO/d
        real                             :: N    = FillValueReal  !molN/d
        real                             :: P    = FillValueReal  !molP/d
    end type T_ByElement  

    type   T_Particles      
        type (T_ID           )           :: ID
        type (T_Composition  )           :: Composition
        type (T_Ratios       )           :: Ratios                         !Ratios [mgX/mgC]
        integer                          :: ParticleIndex = null_int
        integer                          :: RatioVariable = null_int       !1/0 ratios NC and PC
        integer                          :: Organic       = null_int       !1/0, is this an organic particle?
        integer                          :: Silica        = null_int       !1/0, this particle has silica?
        real                             :: Size          = FillValueReal  !cm, mean length of the food
        real                             :: F_E           = FillValueReal  !molCReserves/molCTotalFood, fraction of res
        type (T_Particles),pointer       :: Next   
    end type T_Particles  

    type   T_Predator      
        type (T_ID           )           :: ID             
        real                             :: PredatorSize       = FillValueReal  !cm, size of the predator
        real                             :: MinPreySize        = FillValueReal  !cm, minimum size of the prey
        real                             :: MaxPreySize        = FillValueReal  !cm, maximum size of the prey
        real                             :: Feeding_Rate       = FillValueReal  !Feeding rate per individual
        integer                          :: Feeding_Units      = null_int       !1-#/d.ind; 2-AFDW/d.ind, 3-J/cm2.d
        integer                          :: Feeding_Time       = null_int       !1-Always; 2-LowTide, 3-HighTide
        logical                          :: Feeding            = OFF            !is the predator feeding?
        real                             :: Diet               = FillValueReal  !fraction of mussels in the predator food
        real                             :: AfdwToC            = FillValueReal  !conversion of afdw to Dw
        real                             :: DwToC              = FillValueReal  !conversion of Dw to Carbon
        integer                          :: SIMPLE_TEMP        = null_int       !1/0,Compute simple temperature correction factor?
        integer                          :: CORRECT_TEMP       = null_int       !1/0,Compute simple temperature correction factor?
        real                             :: P_Tref             = FillValueReal  !K, Rate Temperature reference, for predators
        real                             :: P_TA               = FillValueReal  !K, Arrhenius temperature, for predators
        real                             :: P_TL               = FillValueReal  !K, Lower Boundary tolerance range, for predators
        real                             :: P_TH               = FillValueReal  !K, Upper Boundary tolerance range, for predators
        real                             :: P_TAL              = FillValueReal  !K, Arrhenius lower boundary, for predators
        real                             :: P_TAH              = FillValueReal  !K, Arrhenius upper boundary, for predators
        real                             :: TempCorrection     = FillValueReal !adim, temperature correction factor
        real                             :: TotalFeeding_Rate  = FillValueReal  !Computed based on the predator abundance
        type (T_Predator),pointer        :: Next   
    end type T_Predator  

    type     T_InorganicFluxes       
        real                             :: CO2  = FillValueReal  !molCO2/d, amount of CO2 produced
        real                             :: H2O  = FillValueReal  !molH2O/d, amount of H2O produced
        real                             :: O2   = FillValueReal  !molO2/d, amount of O2 consumed
        real                             :: NH3  = FillValueReal  !molNH3/d, amount of ammonia produced
        real                             :: PO4  = FillValueReal  !molPO4/d, amount of phosphate produced
    end type T_InorganicFluxes       

    type   T_Processes 
        real                             :: ClearanceRate                = FillValueReal  !m3/d, ClearanceRate
        real                             :: FilteredInorganic            = FillValueReal  !g/d, filtered inorganic material 
        type(T_ByElement )               :: FilteredFood                                  !mol/d, filtered food 
        real                             :: IngestionInorganic           = FillValueReal  !mg/d, ingested inorganic material 
        type(T_ByElement )               :: IngestionFood                                 !mol/d,ingested food 
        real                             :: PFContributionInorganic      = FillValueReal  !mg/d, pseudofaeces from inorg material
        type(T_ByElement )               :: PFContributionFood                            !mol/d, pseudofaeces from food 
        type(T_ByElement )               :: Assimilation                                  !molC(res)/d, JEA, assimilation flux
        real                             :: FaecesContributionInorganic  = FillValueReal  !mg/d, faeces from inorganic material
        type(T_ByElement )               :: FaecesContributionFood                        !mol/d, faeces contribution from food 
        real                             :: SomaticMaintenance           = FillValueReal  !molC(res)/d, JEM, somatic maintenance
        real                             :: Mobilization                 = FillValueReal  !molC(res)/d, JEC, mobilization flux
        real                             :: ReservesDynamics             = FillValueReal  !molC(res)/d, JE, reserves dynamics
        real                             :: ToGrowthAndSomatic           = FillValueReal  !molC(res)/d, k fraction
        real                             :: ToGrowth                     = FillValueReal  !molC(res)/d,  flux to growth
        real                             :: GametesLoss                  = FillValueReal  !molC(res)/d, loss for maintenance
        real                             :: StructureLoss                = FillValueReal  !molC(res)/d, to shrink
        real                             :: SomaticMaintenanceNeeds      = FillValueReal  !molC(res)/d, somatic maintenance needs
        real                             :: StructureDynamics            = FillValueReal  !molC(str)/d, JV, flux to growth
        real                             :: ToMaturityAndReproduction    = FillValueReal  !molC(res)/d, flux to mat and reprod     
        real                             :: MaturityMaintenance          = FillValueReal  !molC(res)/d, JEJ, maturity maintenance
        real                             :: FluxToMatORRepr              = FillValueReal  !molC(res)/d, JER, flux to mat or reprod     
        real                             :: MaturityLoss                 = FillValueReal  !molC(res)/d, lose of maturity
        real                             :: FluxToGametes                = FillValueReal  !molC(res)/d, JER_R, flux to reproduction
        real                             :: FluxToMaturity               = FillValueReal  !molC(res)/d, JER_M, flux to maturity
        real                             :: MaturityDynamics             = FillValueReal  !molC(str)/d, maturity dynamics
        real                             :: RemainMRReproduction         = FillValueReal  !molC(str)/d, remains in reprod buffer
        real                             :: Spawning                     = FillValueReal  !molC(res)/d, JESpaw, gamets spawned    
        real                             :: SpawningOverhead             = FillValueReal  !molC(res)/d, JESpawOV, before spawning    
        real                             :: GametesToRelease             = FillValueReal  !#/d, JESpaw, number of gametes released    
        real                             :: NewbornsThisCohort           = FillValueReal  !#/d, number of new born individuals  
        real                             :: NONewbornsThisCohort         = FillValueReal  !#/d, number of new born individuals  
        real                             :: ReproductionDynamics         = FillValueReal  !molC(res)/d, JR, flux to reprod
        type(T_InorganicFluxes)          :: InorganicFluxes             
        real                             :: DeathByAge                   = 0.0  !#/d, deaths to age             
        real                             :: DeathByOxygen                = 0.0  !#/d, deaths to lack of oxygen             
        real                             :: DeathByStarvation            = 0.0  !#/d, deaths to starvation            
        real                             :: DeathByNatural               = 0.0  !#/d, deaths to natural            
        real                             :: PredationByShrimps           = 0.0  !#/d, deaths to shrimp             
        real                             :: PredationByCrabs             = 0.0  !#/d, deaths to crab             
        real                             :: PredationByOysterCatchers    = 0.0  !#/d, deaths to oystercatcher             
        real                             :: PredationByEiderDucks        = 0.0  !#/d, deaths to eider ducks             
        real                             :: PredationByHerringGull       = 0.0  !#/d, deaths to HerringGulls             
        real                             :: DeathByLowNumbers            = 0.0  !#/d, deaths to low numbers in the cohort             
    end type T_Processes        


    type   T_PopulationProcesses 
        real                             :: TNStartTimeStep              = 0.0  
        real                             :: TN                           = 0.0  
        real                             :: NCoh                         = 0.0  
        real                             :: TBio                         = 0.0                 
        real                             :: Cr                           = 0.0  
        real                             :: Fil                          = 0.0                 
        real                             :: Ing                          = 0.0  
        real                             :: Ass                          = 0.0                 
        real                             :: CO2                          = 0.0                 
        real                             :: H2O                          = 0.0  
        real                             :: O                            = 0.0                 
        real                             :: NH3                          = 0.0  
        real                             :: PO4                          = 0.0  
        real                             :: m_A                          = 0.0  
        real                             :: m_O                          = 0.0  
        real                             :: m_F                          = 0.0  
        real                             :: m_nat                        = 0.0  
        real                             :: m_shr                        = 0.0  
        real                             :: m_cra                        = 0.0  
        real                             :: m_oys                        = 0.0  
        real                             :: m_duck                       = 0.0  
        real                             :: m_gull                       = 0.0  
        real                             :: m_low                        = 0.0  
        real                             :: Massm_A                      = 0.0  
        real                             :: Massm_O                      = 0.0  
        real                             :: Massm_F                      = 0.0  
        real                             :: Massm_nat                    = 0.0  
        real                             :: Massm_shr                    = 0.0  
        real                             :: Massm_cra                    = 0.0  
        real                             :: Massm_oys                    = 0.0  
        real                             :: Massm_duck                   = 0.0  
        real                             :: Massm_gull                   = 0.0  
        real                             :: Massm_low                    = 0.0  
        real                             :: TNField                      = 0.0 !#/d, deaths to age             
        real                             :: MaxLength                    = 0.0 !#/d, deaths to lack of oxygen             
        real                             :: LastLength                   = FillValueReal !length of the last cohort before death
        real, pointer, dimension(:)      :: SumLogAllMortalityInNumbers  !product of all death ratesof al instants
        real, pointer, dimension(:)      :: SumAllMortalityInMass        !product of all death ratesof al instants
        real, pointer, dimension(:)      :: AverageMortalityInNumbers    !geometricAverage of all death ratesof al instants
        real, pointer, dimension(:)      :: LastCauseofDeath                   !death rates from the last cohort
        integer                          :: nInstantsForAverage          = null_int
        integer                          :: nSpawning                    = null_int !number of spawning events
        real                             :: nNewborns                    = 0
    end type T_PopulationProcesses        
     
    type     T_Output
        integer                          :: Unit
        integer                          :: nParticles
        character(len=StringLength)      :: FileName    = '   '    
        real, dimension(:), pointer      :: Aux
    end type T_Output

    type     T_Cohort
        type(T_ID                    )   :: ID
        type(T_StateIndex            )   :: StateIndex
        type(T_BivalveCondition      )   :: BivalveCondition
        type(T_Processes             )   :: Processes
        real,  pointer, dimension(:,:)   :: FeedingOn         !to store, Col = Filtered ingested assimilated (molC/g.d.ind)
        type(T_Output                )   :: CohortOutput
        integer                          :: Dead = 0
        integer                          :: GlobalDeath = 1
        type(T_Cohort ), pointer         :: Next
    end type T_Cohort

    type     T_Species
        type(T_ID                   )    :: ID
        type(T_Cohort)    , pointer      :: FirstCohort
        type(T_Particles) , pointer      :: FirstParticles
        type(T_Predator)  , pointer      :: FirstPredator
        type(T_SpeciesComposition   )    :: SpeciesComposition
        type(T_IndividualParameters )    :: IndividualParameters
        type(T_AuxiliarParameters   )    :: AuxiliarParameters
        type(T_Output               )    :: PopulationOutput
        type(T_Output               )    :: SizeDistributionOutput
        type(T_Output               )    :: TestingParametersOutput
        type(T_PopulationProcesses  )    :: PopulationProcesses
        logical                          :: CohortOutput = OFF 
        logical                          :: Population   = OFF 
        logical                          :: BySizeOutput = OFF 
        character(len=StringLength)      :: Testing_File          
        real                             :: SizeStep                 = FillValueReal
        real                             :: Max_SizeClass            = FillValueReal
        real, pointer, dimension(:)      :: SizeClasses
        real, pointer, dimension(:)      :: SizeFrequency
        integer                          :: nSizeClasses             = null_int
        character(len=4)                 :: SizeClassesCharFormat    = '   '
        integer                          :: Initial_nCohorts         = 0
        real                             :: MinObsLength             = 0
        integer                          :: LastCohortID             = 0
        integer                          :: nCohorts                 = 0
        logical                          :: NewbornCohort            = .false.
        integer                          :: nParticles               = 0
        integer                          :: nPredator                = 0
        type(T_Species),    pointer      :: Next
    end type T_Species


    type     T_Bivalve
        integer                          :: InstanceID
        integer                          :: ObjTime                  = 0
        integer                          :: ObjEnterData             = 0
        integer                          :: DensityUnits             = 0 ! 0: m2, 1:m3
        real                             :: DT
        real                             :: DTDay
        type (T_Size1D)                  :: Array
        type (T_Size1D)                  :: Prop
        integer                          :: nSpecies                 = 0
        real                             :: LackOfFood               = 0
        integer, dimension(:), pointer   :: PropertyList
        integer                          :: nPropertiesFromBivalve   = 0
        integer                          :: nCohortProperties        = 7 !Each cohort has 7 associated properties
        real                             :: MinNumber
        integer, dimension(:), pointer   :: ListDeadIDs  
        integer                          :: nLastDeadID = 0
        integer, dimension(:), pointer   :: ListNewbornsIDs !List of SpeciesID with newborns  
        integer                          :: nLastNewbornsID          = 0
        real, dimension(:,:)   , pointer :: MatrixNewborns !col = SpeciesID | Index +1  (nNewborns)
        real                             :: DT_OutputTime
        logical                          :: Testing_Parameters       = OFF
        logical                          :: OutputON
        type (T_Time          )          :: CurrentTime, NextOutputTime
        type (T_Output        )          :: MassOutput
        type (T_PropIndex     )          :: PropIndex
        type (T_ComputeOptions)          :: ComputeOptions
        type (T_Species       ), pointer :: FirstSpecies
        type (T_ExternalVar   )          :: ExternalVar
        type (T_Bivalve       ), pointer :: Next
        real                             :: MassLoss                 = 0.0 
        !character(len = PathLength)     :: PathFileName = '/home/saraiva/00_Projects/Parametric/Running/' !biocluster
        character(len = PathLength)      :: PathFileName             = "  " 
    end type T_Bivalve


    !Global Module Variables
    type (T_Bivalve       ), pointer     :: FirstObjBivalve
    type (T_Bivalve       ), pointer     :: Me

    !integer            :: mBivalve_ 

    !-------------------------------------------------------------------------------

    contains

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    !CONSTRUCTOR CONSTRUCTOR CONSTRUCTOR CONSTRUCTOR CONSTRUCTOR CONSTRUCTOR CONSTRU

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    subroutine ConstructBivalve(ObjBivalveID, FileName, STAT)

        !Arguments------------------------------------------------------------------
        integer                           :: ObjBivalveID
        character(len=*)                  :: FileName
        integer, optional, intent(OUT)    :: STAT     

        !External-------------------------------------------------------------------
        integer                           :: ready_, STAT_CALL         

        !Local----------------------------------------------------------------------
        integer                           :: STAT_

        !---------------------------------------------------------------------------

        STAT_ = UNKNOWN_

        !Assures nullification of the global variable
        if (.not. ModuleIsRegistered(mBivalve_)) then
            nullify (FirstObjBivalve)
            call RegisterModule (mBivalve_) 
        endif

        call Ready(ObjBivalveID, ready_)    

cd1 :   if (ready_ .EQ. OFF_ERR_) then

            call AllocateInstance

            call ConstructEnterData(Me%ObjEnterData, trim(FileName), STAT = STAT_CALL) 
            if (STAT_CALL .NE. SUCCESS_)  &         
                stop 'Subroutine ConstructBivalve - ModuleBivalve - ERR01'

            call ReadDataBivalve

            call PropertyIndexNumber

            call ConstructPropertyList

            call KillEnterData(Me%ObjEnterData, STAT = STAT_CALL) 

            if (STAT_CALL .NE. SUCCESS_)  &         
                stop 'Subroutine ConstructBivalve - ModuleBivalve - ERR02'

            !Returns ID
            ObjBivalveID          = Me%InstanceID

            STAT_ = SUCCESS_

        else 

            stop 'Subroutine ConstructBivalve - ModuleBivalve - ERR03' 

        end if cd1

        if (present(STAT)) STAT = STAT_

    end subroutine ConstructBivalve

    !-------------------------------------------------------------------------------

    subroutine AllocateInstance

        !Arguments------------------------------------------------------------------

        !Local----------------------------------------------------------------------
        type (T_Bivalve), pointer           :: NewObjBivalve
        type (T_Bivalve), pointer           :: PreviousObjBivalve


        !Allocates new instance
        allocate (NewObjBivalve     )
        nullify  (NewObjBivalve%Next)

        !Insert New Instance into list and makes Current point to it
        if (.not. associated(FirstObjBivalve)) then
            FirstObjBivalve          => NewObjBivalve
            Me         => NewObjBivalve
        else
            PreviousObjBivalve       => FirstObjBivalve
            Me         => FirstObjBivalve%Next
            
            do while (associated(Me))
                PreviousObjBivalve   => Me
                Me     => Me%Next
            enddo
            
            Me         => NewObjBivalve
            PreviousObjBivalve%Next  => NewObjBivalve
        endif

        Me%InstanceID = RegisterNewInstance (mBivalve_)

    end subroutine AllocateInstance

    !-------------------------------------------------------------------------------

    subroutine ReadDataBivalve

        call ConstructGlobalVariables

        call ConstructSpecies

        if (Me%OutputON) call ConstructOutputs   

    end subroutine ReadDataBivalve

    !-------------------------------------------------------------------------------

    subroutine ConstructGlobalVariables

        !External-------------------------------------------------------------------
        integer             :: flag, STAT_CALL

        !Local----------------------------------------------------------------------
        integer             :: FromFile 

        !Begin----------------------------------------------------------------------

        call GetExtractType    (FromFile = FromFile)

        call GetData(Me%DT                                                  , &
                    Me%ObjEnterData, flag                                   , &
                    SearchType   = FromFile                                 , &
                    keyword      ='DT'                                      , &       
                    default      = 3600.0                                   , & 
                    ClientModule = 'ModuleBivalve'                          , &
                    STAT         = STAT_CALL)

        if (STAT_CALL .NE. SUCCESS_)                                          &
            stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR01'

cd1:    if (flag .EQ. 0) then
            write(*,*) 
            write(*,*) 'Keyword DT not found in ModuleBivalve data file.'
            write(*,*) 'Subroutine ConstructGlobalVariables-ModuleBivalve-WRN01'
            write(*,*) 'Assumed ', Me%DT , &
                       'seconds (',  Me%DT / 3600.0, 'hour).'
            write(*,*) 
        end if cd1

        !Convert DT [seconds] in DT [day]
        Me%DTDay = Me%DT / 24.0 / 60.0 / 60.0

        call GetData(Me%ComputeOptions%PelagicModel                         , &
                    Me%ObjEnterData,  flag                                  , &
                    SearchType   = FromFile                                 , &
                    keyword      = 'PELAGIC_MODEL'                          , &
                    ClientModule = 'ModuleBivalve'                          , &
                    STAT         = STAT_CALL)

        if (STAT_CALL .NE. SUCCESS_)                                          &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR02'

cd2:    if(flag==0)then
            write(*,*)'Please define the pelagic model to couple with ModuleBivalve'
            stop 'ConstructGlobalVariables - ModuleBivalve - ERR03'
        end if cd2

cd3:    if((Me%ComputeOptions%PelagicModel .ne. WaterQualityModel .and. Me%ComputeOptions%PelagicModel .ne. LifeModel))then
            write(*,*)'Pelagic model to couple with ModuleBivalve must be one of the following:'
            write(*,*)trim(WaterQualityModel)
            write(*,*)trim(LifeModel)
            stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR04'
        end if cd3

        call GetData(Me%ComputeOptions%Nitrogen                             , &
                    Me%ObjEnterData, flag                                   , &
                    SearchType = FromFile                                   , &
                    keyword='NITROGEN'                                      , &
                    ClientModule = 'ModuleBivalve'                          , &
                    STAT       = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)                                          &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR05'


        call GetData(Me%ComputeOptions%Phosphorus                           , &
                    Me%ObjEnterData, flag                                   , &
                    SearchType   = FromFile                                 , &
                    keyword      = 'PHOSPHOR'                               , &
                    Default      = .false.                                  , &
                    ClientModule = 'ModuleBivalve'                          , &
                    STAT         = STAT_CALL)
        if(STAT_CALL .NE. SUCCESS_)                                           &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR06'


        call GetData(Me%ComputeOptions%SimpleFiltration                    , &
                    Me%ObjEnterData, flag                                  , &
                    SearchType   = FromFile                                , &
                    keyword      = 'SIMPLE_FILTRATION'                     , &
                    Default      = .false.                                 , &
                    ClientModule = 'ModuleBivalve'                         , &
                    STAT         = STAT_CALL)
        if(STAT_CALL .NE. SUCCESS_)                                          &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR07'

        call GetData(Me%ComputeOptions%CorrectFiltration                   , &
                    Me%ObjEnterData, flag                                  , &
                    SearchType   = FromFile                                , &
                    keyword      = 'CORRECT_FILTRATION'                    , &
                    Default      = .false.                                 , &
                    ClientModule = 'ModuleBivalve'                         , &
                    STAT         = STAT_CALL)
        if(STAT_CALL .NE. SUCCESS_)                                          &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR08'

        call GetData(Me%ComputeOptions%MassBalance                         , &
                    Me%ObjEnterData, flag                                  , &
                    SearchType   = FromFile                                , &
                    keyword      = 'MASS_BALANCE'                          , &
                    Default      = .false.                                 , &
                    ClientModule = 'ModuleBivalve'                         , &
                    STAT         = STAT_CALL)
        if(STAT_CALL .NE. SUCCESS_)                                          &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR09'

        call GetData(Me%MinNumber                                         , &
                    Me%ObjEnterData, flag                                 , &
                    SearchType   = FromFile                               , &
                    keyword      = 'MIN_NUMBER'                           , &
                    Default      = 1.0e-1                                 , &
                    ClientModule = 'ModuleBivalve'                        , &
                    STAT         = STAT_CALL)
        if(STAT_CALL .NE. SUCCESS_)                                         &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR10'

        call GetData(Me%DT_OutputTime                                    , &
                    Me%ObjEnterData, flag                                , &
                    SearchType   = FromFile                              , &
                    keyword      = 'DT_OUTPUT_TIME'                      , &
                    default      = Me%DT                                 , &
                    ClientModule = 'ModuleBivalve'                       , &
                    STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)                                       &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR11'
        
        call GetData(Me%Testing_Parameters                               , &
                    Me%ObjEnterData, flag                                , &
                    SearchType   = FromFile                              , &
                    keyword      = 'TESTING_PARAMETERS'                  , &
                    default      = .false.                               , &
                    ClientModule = 'ModuleBivalve'                       , &
                    STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)                                       &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR12'
        
        call GetData(Me%DensityUnits                                     , &
                    Me%ObjEnterData, flag                                , &
                    SearchType   = FromFile                              , &
                    keyword      = 'DENSITY_UNITS'                       , &
                    default      = 0                                     , &
                    ClientModule = 'ModuleBivalve'                       , &
                    STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)                                       &
        stop 'Subroutine ConstructGlobalVariables - ModuleBivalve - ERR13'
        
    end subroutine ConstructGlobalVariables

    !-------------------------------------------------------------------------------

    subroutine ConstructSpecies

        !Arguments------------------------------------------------------------------

        !Local----------------------------------------------------------------------
        type (T_Species)           , pointer        :: NewSpecies
        integer                                     :: ClientNumber, STAT_CALL
        logical                                     :: BlockFound
        integer                                     :: iCohort

        !Begin----------------------------------------------------------------------


do1 :   do
            call ExtractBlockFromBuffer(Me%ObjEnterData                    , &
                                        ClientNumber    = ClientNumber     , &
                                        block_begin     = '<begin_species>', &
                                        block_end       = '<end_species>'  , &
                                        BlockFound      = BlockFound       , &
                                        STAT            = STAT_CALL)
cd1 :       if(STAT_CALL .EQ. SUCCESS_)then
cd2 :           if (BlockFound) then        

                    call AddSpecies (NewSpecies)

                    call ConstructSpeciesParameters (NewSpecies, ClientNumber)

                        do iCohort = 1, NewSpecies%Initial_nCohorts

                            call ConstructCohort (NewSpecies)

                        end do

                    nullify(NewSpecies)

                else cd2
                
                    call Block_Unlock(Me%ObjEnterData, ClientNumber, STAT = STAT_CALL) 

                    if (STAT_CALL .NE. SUCCESS_)        &
                        stop 'Subroutine ConstructSpecies - ModuleBivalve - ERRO1'

                    exit do1
                end if cd2

            else if (STAT_CALL .EQ. BLOCK_END_ERR_) then cd1
                write(*,*)  
                write(*,*) 'Error calling ExtractBlockFromBuffer. '
                stop 'Subroutine ConstructSpecies - ModuleBivalve - ERR02'
            else cd1
                stop 'Subroutine ConstructSpecies - ModuleBivalve - ERR03'
            end if cd1
        end do do1

    end subroutine ConstructSpecies

    !-------------------------------------------------------------------------------

    subroutine AddSpecies (ObjSpecies)

        !Arguments------------------------------------------------------------------
        type (T_Species),      pointer           :: ObjSpecies
        !Local----------------------------------------------------------------------
        type (T_Species),      pointer           :: PreviousSpecies
        type (T_Species),      pointer           :: NewSpecies
        integer, save                            :: NextSpeciesID = 1

        !Allocates new Species
        allocate (NewSpecies     )
        nullify  (NewSpecies%Next)

        !Insert new Species into list 
cd1:    if (.not. associated(Me%FirstSpecies)) then
            Me%FirstSpecies             => NewSpecies
            ObjSpecies    => NewSpecies
        else
            PreviousSpecies             => Me%FirstSpecies
            ObjSpecies    => Me%FirstSpecies%Next

do1:        do while (associated(ObjSpecies))
                PreviousSpecies         => ObjSpecies
                ObjSpecies=> ObjSpecies%Next
            enddo do1
            ObjSpecies    => NewSpecies
            PreviousSpecies%Next        => NewSpecies
        endif cd1

        !Attributes ID
        ObjSpecies%ID%ID  = NextSpeciesID
        NextSpeciesID     = NextSpeciesID + 1

        Me%nSpecies       = Me%nSpecies + 1

    end subroutine AddSpecies

    !-------------------------------------------------------------------------------

    subroutine ConstructCohort(NewSpecies)

        !Arguments------------------------------------------------------------------
        type (T_Species)        , pointer             :: NewSpecies

        !Local----------------------------------------------------------------------
        type(T_Cohort)          , pointer             :: NewCohort
        character(len=5)                              :: CohortIDStr

        !Begin----------------------------------------------------------------------

        allocate(NewCohort)

        call AddCohort(NewSpecies, NewCohort)

        write(CohortIDStr, ('(i5)'))NewCohort%ID%ID

        NewCohort%ID%Name = trim(adjustl(NewSpecies%ID%Name))//" cohort "//trim(adjustl(CohortIDStr))

        if (NewSpecies%CohortOutput) then

            call ConstructCohortOutput (NewCohort)

        end if

        nullify(NewCohort)

    end subroutine ConstructCohort

    !-------------------------------------------------------------------------------

    subroutine AddCohort (Species, NewCohort)

        !Arguments-------------------------------------------------------------
        type (T_Species),            pointer            :: Species
        type (T_Cohort),            pointer             :: NewCohort

        !Local-----------------------------------------------------------------
        type (T_Cohort),            pointer             :: ObjCohort

        nullify  (NewCohort%Next)

        !Insert new cohort into list
cd1:    if (.not. associated(Species%FirstCohort)) then
            Species%FirstCohort   => NewCohort
        else

            ObjCohort => Species%FirstCohort

do1:        do while (associated(ObjCohort%Next))

                ObjCohort => ObjCohort%Next
            enddo do1

            ObjCohort%Next => NewCohort
        endif cd1

        !Attributes ID
        NewCohort%ID%ID            = Species%LastCohortID + 1

        Species%LastCohortID       = NewCohort%ID%ID

        Species%nCohorts           = Species%nCohorts + 1

    end subroutine AddCohort

    !-------------------------------------------------------------------------------

    subroutine ConstructOutputs

        !Local----------------------------------------------------------------------
            integer                                     :: STAT_CALL,i
            type (T_Species)        , pointer           :: Species
            type (T_Predator)       , pointer           :: Predator
            character(len=500)                          :: SizeDistributionHeader
            character(len=500)                          :: OuputHeader
            character(len=500)                          :: OuputFileName
            character(len=16)                           :: SizeClassNameStr
            character(len=16)                           :: ParameterValueStr
            character(len=16)                           :: ArgumentInComand
        !Begin----------------------------------------------------------------------

        call GetComputeCurrentTime(Me%ObjTime, Me%NextOutputTime, STAT = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine ConstructOutputs - ModuleBivalve - ERR01'

!        call getarg(1,ArgumentInComand)

        Species => Me%FirstSpecies
        do while(associated(Species))
        
            if (Species%Population) then

                call UnitsManager(Species%PopulationOutput%Unit, OPEN_FILE, STAT = STAT_CALL)
                if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine ConstructOutputs - ModuleBivalve - ERR02'

                OuputFileName = trim(ArgumentInComand)//"_"//trim(Species%ID%Name)
                
                !Species population output
                if (Me%Testing_Parameters) then
                
                    Predator => Species%FirstPredator
                    do while(associated(Predator))
                    
                        write(ParameterValueStr, ('(E11.5)')) Predator%Diet
                        
                        OuputFileName = trim(OuputFileName)//'_'//trim(ParameterValueStr)
                    
                        Predator => Predator%Next
                    end do
                
                    write(ParameterValueStr, ('(E11.5)')) Me%DT

                    OuputFileName = trim(OuputFileName)//'_'//trim(ParameterValueStr)

                    write(ParameterValueStr, ('(E11.5)')) Species%IndividualParameters%m_spat

                    OuputFileName = trim(OuputFileName)//'_'//trim(ParameterValueStr)

                    write(ParameterValueStr, ('(E11.5)')) Species%IndividualParameters%m_natural

                    OuputFileName = trim(OuputFileName)//'_'//trim(ParameterValueStr)

                end if

                Species%PopulationOutput%FileName = OuputFileName
                
                OuputFileName = trim(Me%PathFileName)//'Output/'// &
                                trim(Species%PopulationOutput%FileName)//'_'//'population.dat'

                open(Unit = Species%PopulationOutput%Unit, File = trim(OuputFileName), Status = 'REPLACE')

                102 format(A500)

                OuputHeader =   "#YY MM DD hh mm ss"                                                                 // &
                                " #7 #8 molC9 m3/d10 molC/d11 molC/d12 molC/d13"                                     // &
                                " mol/d14 mol/d15 mol/d16 mol/d17 mol/d18 -19"                                       // &
                                " #/d20 #/d21 #/d22 #/d23 #/d24 #/d25 #/d26 #/d27 #/d28 #/d29"                       // &
                                " mol30 mol31 mol32 mol33 mol34 mol35 mol36 mol37 mol38 mol39"                       // &
                                " /d40 /d41 /d42 /d43 /d44 /d45 /d46 /d47 /d48 /d49"   // &
                                " #50 cm51 #52Write"
                                
                write(Species%PopulationOutput%Unit, 102) OuputHeader

                OuputHeader =    "YY MM DD hh mm ss "                                                    // &
                                " TN NCoh TBio Cr Fil Ing Ass"                                      // &
                                " CO H2O O NH3 PO4 LackOfFood"                                     // &
                                " m_A m_O m_F m_nat m_shr m_cra m_oys m_duck m_gull m_low" // &
                                " TMASSm_A TMASSm_O TMASSm_F TMASSm_nat TMASSm_shr TMASSm_cra"     // &
                                " TMASSm_oys TMASSm_duck TMASSm_gull TMASSm_low"                       // &
                                " GEOm_A GEOm_O GEOm_F GEOm_nat GEOm_shr GEOm_cra GEOm_oys"      // &
                                " GEOm_duck GEOm_gull GEOm_low"                                          // &
                                " TNField MaxLength SpawningEvents"

                write(Species%PopulationOutput%Unit, 102) OuputHeader

                OuputFileName = trim(ArgumentInComand)//"_"//trim(Species%ID%Name)

                if (Species%BySizeOutput) then
                
                    Species%SizeDistributionOutput%FileName = Species%PopulationOutput%FileName
                
                    OuputFileName = trim(Me%PathFileName)//'Output/'// &
                                trim(Species%SizeDistributionOutput%FileName)//'_'//'SizeDistribution.dat'

                    !Size Distribution output
                    open(Unit = Species%SizeDistributionOutput%Unit, File = trim(OuputFileName), Status = 'REPLACE')

                    SizeDistributionHeader = 'YY MM DD hh mm ss'

                    do i = 1, Species%nSizeClasses

                        write(SizeClassNameStr, ('(F16.3)')) Species%SizeClasses(i)

                        SizeDistributionHeader = trim(SizeDistributionHeader)//' '//trim(SizeClassNameStr)

                    end do

                    write(Species%SizeDistributionOutput%Unit,102) SizeDistributionHeader

                    !write a dynamic format
                    if    (Species%nSizeClasses .lt. 10                                        )then
                        write(Species%SizeClassesCharFormat, '(i1)')Species%nSizeClasses
                    elseif(Species%nSizeClasses .ge. 10   .and. Species%nSizeClasses .lt. 100  )then
                        write(Species%SizeClassesCharFormat, '(i2)')Species%nSizeClasses
                    elseif(Species%nSizeClasses .ge. 100  .and. Species%nSizeClasses .lt. 1000 )then
                        write(Species%SizeClassesCharFormat, '(i3)')Species%nSizeClasses
                    elseif(Species%nSizeClasses .ge. 1000 .and. Species%nSizeClasses .lt. 10000)then
                        write(Species%SizeClassesCharFormat, '(i4)')Species%nSizeClasses
                    else
                        stop 'Number of volumes limited to 9999.'
                    endif

                end if
            
            end if !population

            Species => Species%Next
        enddo

        103 format(A50)

        if (Me%ComputeOptions%MassBalance) then

            !mass balance results
            call UnitsManager(Me%MassOutput%Unit, OPEN_FILE, STAT = STAT_CALL)
            if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine ConstructOutputs - ModuleBivalve - ERR03'

            open(Unit = Me%MassOutput%Unit, File = 'Output/'// &
                            'MassBalance.dat',&
         Status = 'REPLACE')

            if (Me%ComputeOptions%PelagicModel .eq. LifeModel) then

                write(Me%MassOutput%Unit, 103) "YY MM DD hh mm ss SumC_g SumN_g SumP_g"         

            else

                write(Me%MassOutput%Unit, 103) "Mass Balance only possible to estimate for N and P"         
                write(Me%MassOutput%Unit, 103) "Carbon is not followed when using WaterQuality model"         
                write(Me%MassOutput%Unit, 103) "YY MM DD hh mm ss SumN_g SumP_g"         

            end if
        end if 

    end subroutine ConstructOutputs

    !-------------------------------------------------------------------------------

    subroutine ConstructCohortOutput (Cohort)

        !Local----------------------------------------------------------------------
        integer             :: STAT_CALL
        type (T_Cohort),        pointer   :: Cohort
        character(len=500)  :: OuputHeader

        !Begin----------------------------------------------------------------------

        call UnitsManager(Cohort%CohortOutput%Unit, OPEN_FILE, STAT = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine ConstructOutputs - ModuleBivalve - ERR01'

        !Bivalve processes, bivalve1.dat
        open(Unit = Cohort%CohortOutput%Unit, File = 'Output/'//trim(Cohort%ID%Name)//'.dat', Status = 'REPLACE')

        101 format(A400)

        OuputHeader = "#YY1 MM2 DD3 hh4 mm5 ss6 "   // &
                        " #7 mol8 mol9 mol10 mol11 cm12 y13 m3/d14 g/d15 mol/d16"     // &
                        " g/d17 mol/d18 g/d19 mol/d20 mol/d21 g/d22 mol/d23 mol/d24 mol/d25 mol/d26"// &
                        " mol/d27 mol/d28 mol/d29 mol/d30 mol/d31 mol/d32 #33 mol/d34"// &
                        " mol/d35 mol/d36 mol/d37 mol/d38 mol/d39 "     // &
                        " #/d40 #/d41 #/d42 #/d43 #/d44 #/d45 #/d46 #/d47 #/d48"

        write(Cohort%CohortOutput%Unit, 101) OuputHeader

        OuputHeader = "YY1 MM2 DD3 hh4 mm5 ss6 "   // &
                        " Number7 ME8 MV9 MH10 MR11 L12 A13 Cr14 FInorg15 F16"        // &
                        " IInorg17 I18 PFInorg19 PF20 Ass21 FAEIng22 FAE23 JEM24 JE25 dE26"         // &
                        " GamLoss27 StruLoss28 JV29 JH30 MatLoss31 JS32 Gam33 JR34"   // &
                        " CO235 H2O36 O237 NH338 PO439"   // &
                        " m_A40 m_O41 m_F42 m_nat43 m_shr44 m_cra45 m_oys46 m_duck47 m_gull48 m_low49"

        write(Cohort%CohortOutput%Unit, 101) OuputHeader

    end subroutine ConstructCohortOutput

    !-------------------------------------------------------------------------------

    subroutine ConstructSpeciesParameters (NewSpecies, ClientNumber)

        !Arguments------------------------------------------------------------------
        type (T_Species),      pointer              :: NewSpecies
        integer                                     :: ClientNumber

        !External-------------------------------------------------------------------
        integer                                     :: flag, STAT_CALL, i
        integer                                     :: FirstLine, Line, LastLine
        logical                                     :: BlockLayersFound
        !character(len = PathLength)                 :: ArgumentInComand 
        !Begin-----------------------------------------------------------------
        
        !Name of Species
        call GetData(NewSpecies%ID%Name             , &
                    Me%ObjEnterData, flag           , &
                    SearchType   = FromBlock        , &
                    keyword      = 'NAME'           , &
                    !default      = ' '             , &
                    ClientModule = 'ModuleBivalve'  , &
                    STAT         = STAT_CALL)
                    
        if (STAT_CALL .NE. SUCCESS_)                  &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR00'

        if(.not. Checkpropertyname(trim(NewSpecies%ID%Name), NewSpecies%ID%IDNumber))then
            write(*,*)trim(NewSpecies%ID%Name)
            stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR01'
        end if 

        !Description of Species
        call GetData(NewSpecies%ID%Description      ,   &
                    Me%ObjEnterData, flag          ,   &
                    SearchType   = FromBlock       ,   &
                    keyword      = 'DESCRIPTION'   ,   &
                    !default      = ' '             ,   &
                    ClientModule = 'ModuleBivalve',   &
                    STAT         = STAT_CALL)

        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR02'

        !Description of Species
        call GetData(NewSpecies%Population          ,   &
        Me%ObjEnterData, flag          ,   &
        SearchType   = FromBlock       ,   &
        keyword      = 'POPULATION'    ,   &
        default      = .true.,             &
        ClientModule = 'ModuleBivalve',   &
        STAT         = STAT_CALL)

        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR03'

        !Number of Cohorts from this species
        call GetData(NewSpecies%Initial_nCohorts        ,             &
        Me%ObjEnterData, flag,             &
        SearchType   = FromBlock           ,             &
        keyword      = 'NUMBER_OF_COHORTS' ,             &
        !default      = ' '   ,             &
        ClientModule = 'ModuleBivalve'     ,             &
        STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR04'

        if(flag==0)then
        write(*,*)"NUMBER_OF_COHORTS must be defined for bivalve species : ", trim(adjustl(NewSpecies%ID%Name))
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR03a'
        endif
        
        !Number of Cohorts from this species
        call GetData(NewSpecies%MinObsLength   ,             &
        Me%ObjEnterData, flag,             &
        SearchType   = FromBlock           ,             &
        keyword      = 'MIN_OBS_LENGTH   ' ,             &
        default      = 0.1                 ,             &
        ClientModule = 'ModuleBivalve'     ,             &
        STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR04a'

        !Option to write Cohort output file
        call GetData(NewSpecies%CohortOutput            ,             &
        Me%ObjEnterData, flag,             &
        SearchType   = FromBlock           ,             &
        keyword      = 'COHORT_OUTPUT'     ,             &
        default      = .true.,             &
        ClientModule = 'ModuleBivalve'     ,             &
        STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR05'

        !Option to write Size Distribution output file
        call GetData(NewSpecies%BySizeOutput            ,             &
        Me%ObjEnterData, flag,             &
        SearchType   = FromBlock           ,             &
        keyword      = 'BYSIZE_OUTPUT'     ,             &
        default      = .true.,             &
        ClientModule = 'ModuleBivalve'     ,             &
        STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR06'

        call GetData(NewSpecies%Testing_File                              , &
                    Me%ObjEnterData, flag                                , &
                    SearchType   = FromFile                              , &
                    keyword      = 'TESTING_FILENAME'                    , &
                    !default      = .false.                               , &
                    ClientModule = 'ModuleBivalve'                       , &
                    STAT         = STAT_CALL)
                    
        if (STAT_CALL .NE. SUCCESS_)     &        
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR06'                                     
        
!        if (flag .eq. 0)    then 
!            call getarg(1,ArgumentInComand)
!            
!            NewSpecies%Testing_File = trim(Me%PathFileName)//'Output/'// &
!                            trim(ArgumentInComand)//"_ParameterTest.dat"
!            
!        end if

!        !Aqui to biocluster
!        NewSpecies%MakeRplotsPopulation%FileName = trim(Me%PathFileName)//'Output/'// &
!                            trim(ArgumentInComand)//'_MakeRplotsAll_population.r'
!        
!        NewSpecies%MakeRplotsSizeDistribution%FileName = trim(Me%PathFileName)//'Output/'// &
!                            trim(ArgumentInComand)//'_MakeRplotsAll_SizeDistribution.r'

        !Step to define size classes in the Size Distribution output file
        call GetData(NewSpecies%SizeStep,               &
        Me%ObjEnterData, flag,             &
        SearchType   = FromBlock,          &
        keyword      = 'SIZE_STEP',        &
        default      = 2.0,                &
        ClientModule = 'ModuleBivalve',    &
        STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR07'

        !Step to define size classes in the Size Distribution output file
        call GetData(NewSpecies%Max_SizeClass,          &
        Me%ObjEnterData, flag,             &
        SearchType   = FromBlock,          &
        keyword      = 'MAX_SIZECLASS',    &
        default      = 18.0,               &
        ClientModule = 'ModuleBivalve',    &
        STAT         = STAT_CALL)
        if (STAT_CALL .NE. SUCCESS_)      &
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR08'

        if(flag == 0)then

        call ExtractBlockFromBlock( Me%ObjEnterData,            & 
        ClientNumber,               &
        '<<begin_size_classes>>',   &
        '<<end_size_classes>>',     &
        BlockLayersFound,           &
        FirstLine = FirstLine,      &
        LastLine  = LastLine,       &
        STAT      = STAT_CALL)
        if (STAT_CALL .EQ. SUCCESS_)then    
        if (BlockLayersFound) then

        NewSpecies%nSizeClasses = (LastLine - FirstLine - 1)
        allocate(NewSpecies%SizeClasses(1:NewSpecies%nSizeClasses))  !To sort individuals by size class
        NewSpecies%SizeClasses = 0.0


        allocate(NewSpecies%SizeFrequency(1:NewSpecies%nSizeClasses))  !To sort individuals by size class
        NewSpecies%SizeFrequency = 0.0

        Line = FirstLine + 1

        do  i = 1, NewSpecies%nSizeClasses

        call GetData(NewSpecies%SizeClasses(i), Me%ObjEnterData,    &
        flag, Buffer_Line  = Line, STAT = STAT_CALL)
        if (STAT_CALL /= SUCCESS_)stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR09'

        Line = Line + 1

        enddo

        else
        write(*,*)'Block <<begin_size_classes>> <<end_size_classes>> not found'
        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR10'
        endif

        else

        stop 'Subroutine ConstructSpeciesParameters - ModuleBivalve - ERR11'

        endif

        else

        NewSpecies%nSizeClasses = int(NewSpecies%Max_SizeClass/NewSpecies%SizeStep) + 1

        allocate(NewSpecies%SizeClasses(1:NewSpecies%nSizeClasses))  !To sort individuals by size class
        NewSpecies%SizeClasses = 0.0

        allocate(NewSpecies%SizeFrequency(1:NewSpecies%nSizeClasses))  !To sort individuals by size class
        NewSpecies%SizeFrequency = 0.0

        do i = 2, NewSpecies%nSizeClasses

        NewSpecies%SizeClasses(i) = NewSpecies%SizeClasses(i-1) + NewSpecies%SizeStep

        end do

        endif
        
        allocate(NewSpecies%PopulationProcesses%LastCauseofDeath(10)) !know the main cause of death
        allocate(NewSpecies%PopulationProcesses%SumLogAllMortalityInNumbers(10)) !know the main cause of death
        allocate(NewSpecies%PopulationProcesses%SumAllMortalityInMass(10)) !know the main cause of death
        allocate(NewSpecies%PopulationProcesses%AverageMortalityInNumbers(10)) !know the main cause of death
        NewSpecies%PopulationProcesses%LastCauseofDeath = 0.0
        NewSpecies%PopulationProcesses%SumLogAllMortalityInNumbers = 0.0
        NewSpecies%PopulationProcesses%SumAllMortalityInMass = 0.0
        NewSpecies%PopulationProcesses%AverageMortalityInNumbers = 0.0
        
        NewSpecies%PopulationProcesses%nInstantsForAverage = 0.0
        
        NewSpecies%PopulationProcesses%nSpawning = 0
        
        call ConstructSpeciesComposition    (NewSpecies%SpeciesComposition   )
        call ConstructIndividualParameters  (NewSpecies%IndividualParameters )
        call ConstructParticles             (NewSpecies, ClientNumber        )
        call ConstructPredator              (NewSpecies, ClientNumber        )

    end subroutine ConstructSpeciesParameters

    !-------------------------------------------------------------------------------

    subroutine ConstructSpeciesComposition (SpeciesComposition)

    !Arguments------------------------------------------------------------------
    type (T_SpeciesComposition)         :: SpeciesComposition

    !External-------------------------------------------------------------------
    integer :: flag, STAT_CALL

    !Local----------------------------------------------------------------------
    integer :: FromBlock 

    !Begin----------------------------------------------------------------------

    call GetExtractType    (FromBlock = FromBlock)

    !molH/molC, chemical index of hydrogen in bivalve reserves
    call GetData(SpeciesComposition%ReservesComposition%nC,       &
    Me%ObjEnterData, flag      ,       &
    SearchType   = FromBlock   ,       &
    keyword      = 'RESERVES_nC'             ,       &
    default      = 1.          ,       &
    ClientModule = 'ModuleBivalve'           ,       & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR01'


    !molH/molC, chemical index of hydrogen in bivalve reserves, (Kooijman, 2010)
    call GetData(SpeciesComposition%ReservesComposition%nH,       &
    Me%ObjEnterData, flag      ,       &
    SearchType   = FromBlock   ,       &
    keyword      = 'RESERVES_nH'             ,       &
    default      = 1.8         ,       &
    ClientModule = 'ModuleBivalve'           ,       & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR01'

    !molO/molC, chemical index of oxygen in bivalve reserves, (Kooijman, 2010)
    call GetData(SpeciesComposition%ReservesComposition%nO,       &
    Me%ObjEnterData, flag      ,       &
    SearchType   = FromBlock   ,       &
    keyword      = 'RESERVES_nO'             ,       &
    default      = 0.53        ,       &
    ClientModule = 'ModuleBivalve'           ,       & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR02'

    !molN/molC, chemical index of nitrogen in bivalve reserves, (Smaal and Vonck, 1997)
    call GetData(SpeciesComposition%ReservesComposition%nN,       &
    Me%ObjEnterData, flag      ,       &
    SearchType   = FromBlock   ,       &
    keyword      = 'RESERVES_nN'             ,       &
    default      = 0.15        ,       &
    ClientModule = 'ModuleBivalve'           ,       & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR03'

    !molN/molC, chemical index of phosphorus in bivalve reserves, (Smaal and Vonck, 1997)
    call GetData(SpeciesComposition%ReservesComposition%nP,       &
    Me%ObjEnterData, flag      ,       &
    SearchType   = FromBlock   ,       &
    keyword      = 'RESERVES_nP'             ,       &
    default      = 0.006       ,       &
    ClientModule = 'ModuleBivalve'           ,       &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR04'


    !molC/molC, chemical index of hydrogen in bivalve structure
    call GetData(SpeciesComposition%StructureComposition%nC,      &
    Me%ObjEnterData, flag       ,      &
    SearchType   = FromBlock    ,      &
    keyword      = 'STRUCTURE_nC'             ,      &
    default      =  1.          ,      &
    ClientModule = 'ModuleBivalve'            ,      & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR05'


    !molH/molC, chemical index of hydrogen in bivalve structure, (Kooijman, 2010)
    call GetData(SpeciesComposition%StructureComposition%nH,      &
    Me%ObjEnterData, flag       ,      &
    SearchType   = FromBlock    ,      &
    keyword      = 'STRUCTURE_nH'             ,      &
    default      =  1.8         ,      &
    ClientModule = 'ModuleBivalve'            ,      & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR05'

    !molO/molC, chemical index of oxygen in bivalve structure, (Kooijman, 2010)
    call GetData(SpeciesComposition%StructureComposition%nO,      &
    Me%ObjEnterData, flag       ,      &
    SearchType   = FromBlock    ,      &
    keyword      = 'STRUCTURE_nO'             ,      &
    default      = 0.53         ,      &
    ClientModule = 'ModuleBivalve'            ,      &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR06'

    !molN/molC, chemical index of nitrogen in bivalve structure, (Smaal and Vonck, 1997)
    call GetData(SpeciesComposition%StructureComposition%nN,      &
    Me%ObjEnterData, flag       ,      &
    SearchType   = FromBlock    ,      &
    keyword      = 'STRUCTURE_nN'             ,      &
    default      = 0.15         ,      &
    ClientModule = 'ModuleBivalve'            ,      &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR07'

    !molN/molC, chemical index of phosphorus in bivalve structure, (Smaal and Vonck, 1997)
    call GetData(SpeciesComposition%StructureComposition%nP,      &
    Me%ObjEnterData, flag       ,      &
    SearchType   = FromBlock    ,      &
    keyword      = 'STRUCTURE_nP'             ,      &
    default      = 0.006        ,      &
    ClientModule = 'ModuleBivalve'            ,      &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructSpeciesComposition - ModuleBivalve - ERR08'

    end subroutine ConstructSpeciesComposition

    !-------------------------------------------------------------------------------

    subroutine ConstructIndividualParameters (IndividualParameters)

    !Arguments------------------------------------------------------------------
    type (T_IndividualParameters)       :: IndividualParameters

    !External-------------------------------------------------------------------
    integer :: flag, STAT_CALL

    !Local----------------------------------------------------------------------
    integer :: FromBlock 

    !Begin----------------------------------------------------------------------

    call GetExtractType    (FromBlock = FromBlock)

    !K, Rate Temperature reference
    call GetData(IndividualParameters%Tref      ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'Tref'          ,   &
    default      = 293.0           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR01'


    !K, Arrhenius temperature (van der Veer etal., 2006)
    call GetData(IndividualParameters%TA        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'TA'            ,   &
    default      = 7022.0          ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR02'

    !K, Lower Boundary tolerance range  (van der Veer etal., 2006)
    call GetData(IndividualParameters%TL        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'TL'            ,   &
    default      = 273.0           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR03'

    !K, Upper Boundary tolerance rang  (van der Veer etal., 2006)
    call GetData(IndividualParameters%TH        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'TH'            ,   &
    default      = 290.0           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR04'

    !K, Arrhenius temperature for lower boundary  (van der Veer etal., 2006)
    call GetData(IndividualParameters%TAL       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'TAL'           ,   &
    default      = 45430.0         ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR05'

    !K, Arrhenius temperature for upper boundary  (van der Veer etal., 2006)
    call GetData(IndividualParameters%TAH       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'TAH'           ,   &
    default      = 31376.0         ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR06'

    !adim, constant food density parameter (only if simple filtration)
    call GetData(IndividualParameters%F_FIX     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'F_FIX'         ,   &
    default      = 1.,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR07'

    !Jd-1cm-2, bivalve surface-specific assimilation rate if fix (Saraiva etal., inpress)   
    call GetData(IndividualParameters%PAM_FIX   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'PAM_FIX'       ,   &
    default      = 80.5            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR08'

    !cm(volumetric)/cm(real), shape coefficient  (Saraiva etal., inpress)
    call GetData(IndividualParameters%delta_M   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'DELTA_M'       ,   &
    default      = 0.297           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR09'

    !years, life span of a mussel, Sukhotin et al. (2007)
    call GetData(IndividualParameters%LifeSpan  ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'LIFE_SPAN'     ,   &
    default      = 24.0            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR10'

    !%, natural mortality rate
    call GetData(IndividualParameters%m_natural   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'M_NATURAL'     ,   &
    default      = 0.0             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR11'

    !%, spat mortality rate
    call GetData(IndividualParameters%m_spat    ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'M_SPAT'        ,   &
    default      = 0.0             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR12'

    !cm/d, energy conductance (Saraiva etal., in press)    
    call GetData(IndividualParameters%v_cond    ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'V_COND'        ,   &
    default      = 0.056           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR013'

    !adim, allocation fraction to growth/somatic maintenace (Saraiva etal., inpress) 
    call GetData(IndividualParameters%kappa     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'KAPPA'         ,   &
    default      = 0.67            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR14'

    !adim, fraction of flux allocated to reproduction (Kooijman, 2010)
    call GetData(IndividualParameters%kap_R     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'KAP_R'         ,   &
    default      = 0.95            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR15'

    !J/(d.cm3), volume specific somatic maintenace energy flux (Saraiva etal., inpress) 
    call GetData(IndividualParameters%pM        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'pM'            ,   &
    default      = 11.6            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR16'

    !J/cm3(volumetric), energy costs for structural volume growth (Saraiva etal., inpress)
    call GetData(IndividualParameters%EG        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'EG'            ,   &
    default      = 5993.           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR17'


    !J, Maturity threshold for birth (Saraiva etal., inpress)
    call GetData(IndividualParameters%EHb       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'EH_B'          ,   &
    default      = 2.99e-5         ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR18'

    !J, Maturity threshold for puberty (Saraiva etal., inpress)
    call GetData(IndividualParameters%EHp       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'EH_P'          ,   &
    default      = 1.58e2          ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR19'

    !m3/d.cm2, maximum clearance rate (Saraiva etal., 2011) 
    call GetData(IndividualParameters%Crm       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'CRM'           ,   &
    default      = 0.096           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR20'

    !molC/(d.cm2), algae maximum surface area-specific filtration rate (Thomas etal., 2011) 
    call GetData(IndividualParameters%JX1Fm     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'JX1FM'         ,   &
    default      = 4.8e-4          ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR21'

    !g/(d.cm2), inorganic material maximum surface area-specific filtration rate (Saraiva etal., 2011) 
    call GetData(IndividualParameters%JX0Fm     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'JX0FM'         ,   &
    default      = 3.5             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR22'

    !adim, algae binding probability (Saraiva etal., inpress)
    call GetData(IndividualParameters%ro_X1     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'RO_XI'         ,   &
    default      = 0.4             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR23'

    !adim, inorganic material binding probability (Saraiva etal., inpress)
    call GetData(IndividualParameters%ro_X0     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'RO_X0'         ,   &
    default      = 0.4             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR24'

    !molC/(d.cm2), algae maximum surface area-specific ingestion rate (Saraiva etal., 2011) 
    call GetData(IndividualParameters%JX1Im     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'JX1IM'         ,   &
    default      = 1.3e4           ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR25'

    !g/(d.cm2), inorganic material maximum surface area-specific ingestion rate (Saraiva etal., 2011) 
    call GetData(IndividualParameters%JX0Im     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'JX0IM'         ,   &
    default      = 0.11            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR26'

    !molC(res)/molC(food), yield coeficienct of reserves in algae structure (Kooijman, 2010)        
    call GetData(IndividualParameters%YEX       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'YEX'           ,   &
    default      = 0.75            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR27'

    !molC(gam)/molC(struc), minimum gonado-somatic ratio in the organism (Cardoso et al., 2007)
    call GetData(IndividualParameters%GSR_MIN    ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'GSR_MIN'       ,   &
    default      = 0.1             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR28'

    !molC(gam)/molC(struc), gonado-somatic ratio to spawn (Saraiva etal., submited)  
    call GetData(IndividualParameters%GSR_SPAWN ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'GSR_SPAWN'     ,   &
    default      = 0.2             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR29'

    !oC, minimum temperature for spawning (Hummel etal., 1989)
    call GetData(IndividualParameters%T_SPAWN   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'T_SPAWN'       ,   &
    default      = 9.6             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR30'

    !d, minimum time interval between spawning events    
    call GetData(IndividualParameters%MIN_SPAWN_TIME,             &
    Me%ObjEnterData, flag,             &
    SearchType   = FromBlock           ,             &
    keyword      = 'MIN_SPAWN_TIME'    ,             &
    default      = 0.    ,             &
    ClientModule = 'ModuleBivalve'     ,             & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR31'



    !molC(reser), reserves in an embryo at optimal food conditions (Saraiva etal., submited)    
    call GetData(IndividualParameters%ME_0      ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'ME_0'          ,   &
    default      = 1.48e-10        ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR32'

    !molC, reserves in a new born individual at optimal food conditions (Saraiva etal., submited) 
    call GetData(IndividualParameters%MEb       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'ME_B'          ,   &
    default      = 1.0e-7          ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR33'


    !molC, structure in a new born individual at optimal food conditions (Saraiva etal., submited) 
    call GetData(IndividualParameters%MVb       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'MV_B'          ,   &
    default      = 7.52e-11        ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR34'

    !molC, maturity in a new born individual at optimal food conditions (Saraiva etal., submited) 
    call GetData(IndividualParameters%MHb       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'MH_B'          ,   &
    default      = 4.24e-11        ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR35'

    !molC, length in a new born individual at optimal food conditions (Saraiva etal., submited) 
    call GetData(IndividualParameters%Lb        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'L_B'           ,   &
    default      = 7.3e-3          ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR36'

    !g(dw)/cm3, bivalve structure and reserves specific density (Rosland etal., 2009 and Brey, 2001)
    call GetData(IndividualParameters%d_V       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'DV'            ,   &
    default      = 0.2             ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR37'

    !J/molC(reser), chemical potential of reserves (van der Veer etal., 2006)
    call GetData(IndividualParameters%mu_E      ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'MU_E'          ,   &
    default      = 6.97e5          ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR38'

    !option to compute simple assimilation 
    call GetData(IndividualParameters%SIMPLE_ASSI,  &
    Me%ObjEnterData, flag           ,  &
    SearchType   = FromBlock        ,  &
    keyword      = 'SIMPLE_ASSI'    ,  &
    default      = 0  ,  &
    ClientModule = 'ModuleBivalve'  ,  & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR39'

    !option to compute simple temperature correction factor 
    call GetData(IndividualParameters%SIMPLE_TEMP,  &
    Me%ObjEnterData, flag           ,  &
    SearchType   = FromBlock        ,  &
    keyword      = 'SIMPLE_TEMP'    ,  &
    default      = 1  ,  &
    ClientModule = 'ModuleBivalve'  ,  & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructIndividualParameters - ModuleBivalve - ERR40'


    end subroutine ConstructIndividualParameters

    !-------------------------------------------------------------------------------

    subroutine ConstructParticles (NewSpecies, ClientNumber)

    !Arguments------------------------------------------------------------------
    type (T_Species) , pointer          :: NewSpecies
    integer :: ClientNumber

    !External-------------------------------------------------------------------
    integer :: STAT_CALL

    !Local----------------------------------------------------------------------
    integer :: FirstLine, LastLine
    logical :: BlockInBlockFound
    type (T_Particles)             , pointer          :: NewParticles

    !Begin----------------------------------------------------------------------

    do1 :   do
    call ExtractBlockFromBlock(Me%ObjEnterData             , &
    ClientNumber      = ClientNumber         , &
    block_begin       = '<<begin_particle>>' , &
    block_end         = '<<end_particle>>'   , &
    BlockInBlockFound = BlockInBlockFound    , &
    FirstLine         = FirstLine            , &
    LastLine          = LastLine             , &
    STAT= STAT_CALL)

    cd1 :       if(STAT_CALL .EQ. SUCCESS_)then
    cd2 :           if (BlockInBlockFound) then        

    allocate(NewParticles)

    call AddParticles (NewSpecies, NewParticles)

    call ConstructParticlesParameters (NewParticles)

    nullify(NewParticles)

    else cd2

    exit do1
    end if cd2

    else if (STAT_CALL .EQ. BLOCK_END_ERR_) then cd1
    write(*,*)  
    write(*,*) 'Error calling ExtractBlockFromBuffer. '
    stop 'Subroutine ConstructParticles - ModuleBivalve - ERR02'
    else cd1
    stop 'Subroutine ConstructParticles - ModuleBivalve - ERR03'
    end if cd1
    end do do1

    end subroutine ConstructParticles

    !-------------------------------------------------------------------------------

    subroutine AddParticles (ObjSpecies, NewParticles)

    !Arguments-------------------------------------------------------------
    type (T_Species),            pointer:: ObjSpecies
    type (T_Particles),          pointer:: NewParticles

    !Local-----------------------------------------------------------------
    type (T_Particles),          pointer:: ObjParticles
    integer, save         :: NextParticlesID = 1

    nullify  (NewParticles%Next)

    !Insert new Food into list
    cd1:    if (.not. associated(ObjSpecies%FirstParticles)) then
    NextParticlesID= 1
    ObjSpecies%FirstParticles    => NewParticles
    else

    ObjParticles => ObjSpecies%FirstParticles

    do1:        do while (associated(ObjParticles%Next))

    ObjParticles => ObjParticles%Next
    enddo do1

    ObjParticles%Next => NewParticles
    endif cd1

    !Attributes ID
    NewParticles%ID%ID            = NextParticlesID

    NextParticlesID = NextParticlesID + 1

    ObjSpecies%nParticles         = ObjSpecies%nParticles + 1


    end subroutine AddParticles

    !-------------------------------------------------------------------------------

    subroutine ConstructParticlesParameters (NewParticles)

    !Arguments------------------------------------------------------------------
    type (T_Particles),      pointer          :: NewParticles

    !External-------------------------------------------------------------------
    integer       :: flag, STAT_CALL
    integer       :: FromBlockInBlock
    !Begin----------------------------------------------------------------------


    call GetExtractType    (FromBlockInBlock = FromBlockInBlock)


    call GetData(NewParticles%ID%Name           ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'NAME'          ,   &
    !default      = ' '            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR01'


    call GetData(NewParticles%ID%Description    ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'DESCRIPTION'   ,   &
    !default      = ' '            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR02'

    !Organic?, Is this property organic?  
    call GetData(NewParticles%Organic           ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'ORGANIC'       ,   &
    default      = 0 ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR03'

    !Silica?, Just if the pelagic model is life 
    call GetData(NewParticles%Silica            ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'SILICA_USE'    ,   &
    default      = 0 ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR04'


    !The NC and PC ratios of this property are variable?
    call GetData(NewParticles%RatioVariable     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'RATIO_VARIABLE',   &
    default      =  0,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR05'

    !Ratio H/C [mgH/mgC]
    call GetData(NewParticles%Ratios%HC_Ratio   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'RATIOHC'       ,   &
    default      = 0.15            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR06'      

    !Ratio O/C [mgO/mgC]
    call GetData(NewParticles%Ratios%OC_Ratio   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'RATIOOC'       ,   &
    default      = 0.67            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR07'      

    !Ratio N/C [mgN/mgC]
    call GetData(NewParticles%Ratios%NC_Ratio   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'RATIONC'       ,   &
    default      = 0.16            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR08'      

    !Ratio P/C [mgP/mgC]
    call GetData(NewParticles%Ratios%PC_Ratio   ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'RATIOPC'       ,   &
    default      = 0.024           ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR09'      

    !Ratio Si/C [mgSi/mgC]
    call GetData(NewParticles%Ratios%SiC_Ratio  ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'RATIOSiC'      ,   &
    default      = 0.89            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR10'      

    !Ratio Chla/C [mgChla/mgC]
    call GetData(NewParticles%Ratios%ChlC_Ratio ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'RATIOCHLC'     ,   &
    default      = 0.017           ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR11'      

    !cm, mean size of property
    call GetData(NewParticles%Size,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'SIZE'          ,   &
    default      = 0.2             ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR12'      

    !molCReserves/molCTotalFood, fraction of reserves in the food    
    call GetData(NewParticles%f_E ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'F_E'           ,   &
    default      = 0.5             ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructParticlesParameters - ModuleBivalve - ERR13'


    end subroutine ConstructParticlesParameters

    !-------------------------------------------------------------------------------

    subroutine ConstructPredator (NewSpecies, ClientNumber)

    !Arguments------------------------------------------------------------------
    type (T_Species)             , pointer            :: NewSpecies
    integer :: ClientNumber

    !External-------------------------------------------------------------------
    integer :: STAT_CALL

    !Local----------------------------------------------------------------------
    integer :: FirstLine, LastLine
    logical :: BlockInBlockFound
    type (T_Predator)            , pointer            :: NewPredator

    !Begin----------------------------------------------------------------------

    do1 :   do
    call ExtractBlockFromBlock(Me%ObjEnterData             , &
    ClientNumber      = ClientNumber         , &
    block_begin       = '<<begin_predator>>' , &
    block_end         = '<<end_predator>>'   , &
    BlockInBlockFound = BlockInBlockFound    , &
    FirstLine         = FirstLine            , &
    LastLine          = LastLine             , &
    STAT= STAT_CALL)

    cd1 :       if(STAT_CALL .EQ. SUCCESS_)then
    cd2 :           if (BlockInBlockFound) then        

    allocate(NewPredator)

    call AddPredator (NewSpecies, NewPredator)

    call ConstructPredatorParameters (NewPredator)

    nullify(NewPredator)

    else cd2
    !
    exit do1
    end if cd2

    else if (STAT_CALL .EQ. BLOCK_END_ERR_) then cd1
    write(*,*)  
    write(*,*) 'Error calling ExtractBlockFromBuffer. '
    stop 'Subroutine ConstructPredator - ModuleBivalve - ERR02'
    else cd1
    stop 'Subroutine ConstructPredator - ModuleBivalve - ERR03'
    end if cd1
    end do do1

    end subroutine ConstructPredator

    !-------------------------------------------------------------------------------

    subroutine AddPredator (ObjSpecies, NewPredator)

    !Arguments-------------------------------------------------------------
    type (T_Species),            pointer:: ObjSpecies
    type (T_Predator),          pointer :: NewPredator

    !Local-----------------------------------------------------------------
    type (T_Predator),          pointer :: ObjPredator
    integer, save         :: NextPredatorID = 1

    nullify  (NewPredator%Next)

    !Insert new Food into list
    cd1:    if (.not. associated(ObjSpecies%FirstPredator)) then
    NextPredatorID= 1
    ObjSpecies%FirstPredator    => NewPredator
    else

    ObjPredator => ObjSpecies%FirstPredator

    do1:        do while (associated(ObjPredator%Next))

    ObjPredator => ObjPredator%Next
    enddo do1

    ObjPredator%Next => NewPredator
    endif cd1

    !Attributes ID
    NewPredator%ID%ID            = NextPredatorID

    NextPredatorID = NextPredatorID + 1

    ObjSpecies%nPredator         = ObjSpecies%nPredator + 1


    end subroutine AddPredator

    !-------------------------------------------------------------------------------

    subroutine ConstructPredatorParameters (NewPredator)

    !Arguments------------------------------------------------------------------
    type (T_Predator),      pointer          :: NewPredator

    !External-------------------------------------------------------------------
    integer       :: flag, STAT_CALL
    integer       :: FromBlockInBlock
    !Begin----------------------------------------------------------------------


    call GetExtractType    (FromBlockInBlock = FromBlockInBlock)


    call GetData(NewPredator%ID%Name            ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'NAME'          ,   &
    !default      = ' '            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR01'


    call GetData(NewPredator%ID%Description     ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'DESCRIPTION'   ,   &
    !default      = ' '            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR02'

    !cm, predator size
    call GetData(NewPredator%PredatorSize       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'SIZE'          ,   &
    default      = 0.0             ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR03'


    !cm, minimum size of the prey
    call GetData(NewPredator%MinPreySize        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'MINPREYSIZE'   ,   &
    default      = 0.,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR04'

    !cm, maximum size of the prey
    call GetData(NewPredator%MaxPreySize        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'MAXPREYSIZE'   ,   &
    default      = 0.,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR05'

    !the units depend on the predator, Feeding_Units
    call GetData(NewPredator%Feeding_Rate       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'FEEDING_RATE'  ,   &
    default      =  0.             ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR06'      

    !1-#/d.ind; 2-AFDW/d.ind, 3-J/cm2.d
    call GetData(NewPredator%Feeding_Units      ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'FEEDING_UNITS' ,   &
    default      =  1,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR07'      

    !1-Always; 2-LowTide, 3-HighTide
    call GetData(NewPredator%Feeding_Time       ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'FEEDING_TIME'  ,   &
    default      =  1,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR08'      

    !-, fraction of mussels in the shrimp food (this study)
    call GetData(NewPredator%Diet ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'DIET_FRACTION' ,   &
    default      = 0.15            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR09'      

    !-, conversion of afdw in dw
    call GetData(NewPredator%AfdwToC            ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'AFDW_DW'       ,   &
    default      = 0.85            ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR10'      

    !-, conversion of afdw in dw
    call GetData(NewPredator%DwToC,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlockInBlock,   &
    keyword      = 'DW_C'          ,   &
    default      = 2.5             ,   &
    ClientModule = 'ModuleBivalve' ,   &
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR11'      

    !option to compute simple temperature correction factor 
    call GetData(NewPredator%SIMPLE_TEMP        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'SIMPLE_TEMP'   ,   &
    default      = 1 ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR12'

    !option to compute simple temperature correction factor 
    call GetData(NewPredator%CORRECT_TEMP        ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'CORRECT_TEMP'   ,   &
    default      = 1 ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR12'

    !K, Rate Temperature reference for predator
    call GetData(NewPredator%P_Tref             ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'P_Tref'        ,   &
    default      = 293.            ,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR13'

    !K, Arrhenius temperature for predator 
    call GetData(NewPredator%P_TA ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'P_TA'          ,   &
    default      = 0.,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR14'

    ! K, Lower Boundary tolerance range for predator 
    call GetData(NewPredator%P_TL ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'P_TL'          ,   &
    default      = 0.,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR15'


    !K, Upper Boundary tolerance range for predator 
    call GetData(NewPredator%P_TH ,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'P_TH'          ,   &
    default      = 0.,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR16'

    !K, Arrhenius temperature for lower boundary for predator
    call GetData(NewPredator%P_TAL,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'P_TAL'         ,   &
    default      = 0.,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR17'

    !K, Arrhenius temperature for upper boundary for predator
    call GetData(NewPredator%P_TAH,   &
    Me%ObjEnterData, flag          ,   &
    SearchType   = FromBlock       ,   &
    keyword      = 'P_TAH'         ,   &
    default      = 0.,   &
    ClientModule = 'ModuleBivalve' ,   & 
    STAT         = STAT_CALL)

    if (STAT_CALL .NE. SUCCESS_)      &
    stop 'Subroutine ConstructPredatorParameters - ModuleBivalve - ERR18'

    end subroutine ConstructPredatorParameters

    !-------------------------------------------------------------------------------

    subroutine PropertyIndexNumber

    !Local-----------------------------------------------------------------
    type(T_Species)   , pointer:: Species
    type(T_Particles) , pointer:: Particles
    type(T_Predator)  , pointer:: Predator
    type(T_Cohort)    , pointer:: Cohort

    !Begin-----------------------------------------------------------------

    Me%Prop%ILB = 1
    Me%Prop%IUB = 0

    !Sediments             
    Me%PropIndex%sediments            = null_int   !Cohesive sediments
    !Nitrogen             
    Me%PropIndex%AM     = null_int
    Me%PropIndex%PON    = null_int   !Particulate Organic Nitrogen
    !Phosphorus           
    Me%PropIndex%IP     = null_int   !Inorganic Phosphorus or Phosphate 
    Me%PropIndex%POP    = null_int   !Particulate Organic Phosphorus
    !Carbon 
    Me%PropIndex%POC    = null_int   !Particulate Organic Carbon
    Me%PropIndex%CarbonDioxide        = null_int   !Carbon Dioxide 
    !Oxygen 
    Me%PropIndex%Oxygen = null_int
    !Silica             
    Me%PropIndex%BioSilica            = null_int
    Me%PropIndex%DissSilica           = null_int
    !Food  
    Me%PropIndex%phyto  = null_int
    Me%PropIndex%diatoms= null_int
    Me%PropIndex%zoo    = null_int
    Me%PropIndex%ciliate= null_int
    Me%PropIndex%bacteria             = null_int
    Me%PropIndex%silica = null_int

    Me%PropIndex%DiatomsC= null_int
    Me%PropIndex%DiatomsN= null_int
    Me%PropIndex%DiatomsP= null_int
    Me%PropIndex%DiatomsChl            = null_int
    Me%PropIndex%DiatomsSi             = null_int
    Me%PropIndex%Mix_FlagellateC       = null_int
    Me%PropIndex%Mix_FlagellateN       = null_int
    Me%PropIndex%Mix_FlagellateP       = null_int
    Me%PropIndex%Mix_FlagellateChl     = null_int
    Me%PropIndex%PicoalgaeC            = null_int
    Me%PropIndex%PicoalgaeN            = null_int
    Me%PropIndex%PicoalgaeP            = null_int
    Me%PropIndex%PicoalgaeChl          = null_int
    Me%PropIndex%FlagellateC           = null_int
    Me%PropIndex%FlagellateN           = null_int
    Me%PropIndex%FlagellateP           = null_int
    Me%PropIndex%FlagellateChl         = null_int
    Me%PropIndex%MicrozooplanktonC     = null_int
    Me%PropIndex%MicrozooplanktonN     = null_int
    Me%PropIndex%MicrozooplanktonP     = null_int
    Me%PropIndex%Het_NanoflagellateC   = null_int
    Me%PropIndex%Het_NanoflagellateN   = null_int
    Me%PropIndex%Het_NanoflagellateP   = null_int
    Me%PropIndex%MesozooplanktonC      = null_int
    Me%PropIndex%MesozooplanktonN      = null_int
    Me%PropIndex%MesozooplanktonP      = null_int
    Me%PropIndex%Het_BacteriaC         = null_int
    Me%PropIndex%Het_BacteriaN         = null_int
    Me%PropIndex%Het_BacteriaP         = null_int
    Me%PropIndex%Shrimp  = null_int
    Me%PropIndex%Crab    = null_int
    Me%PropIndex%OysterCatcher         = null_int
    Me%PropIndex%EiderDuck             = null_int
    Me%PropIndex%HerringGull           = null_int

    if (Me%ComputeOptions%PelagicModel .eq. LifeModel) then

    if(Me%PropIndex%POC .eq. null_int)then

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%POC            = Me%Prop%IUB

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%AM             = Me%Prop%IUB

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%PON            = Me%Prop%IUB

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%IP             = Me%Prop%IUB

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%POP            = Me%Prop%IUB

    end if
    end if

    if(Me%ComputeOptions%Nitrogen)then

    if(Me%PropIndex%AM .eq. null_int)then

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%AM             = Me%Prop%IUB
    end if

    if(Me%PropIndex%PON .eq. null_int)then

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%PON            = Me%Prop%IUB
    end if

    end if

    if(Me%ComputeOptions%Phosphorus)then

    if(Me%PropIndex%IP .eq. null_int)then

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%IP             = Me%Prop%IUB
    end if

    if(Me%PropIndex%POP .eq. null_int)then

    Me%Prop%IUB   = Me%Prop%IUB + 1
    Me%PropIndex%POP            = Me%Prop%IUB
    end if

    end if

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%CarbonDioxide      = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%Oxygen             = Me%Prop%IUB

    Species => Me%FirstSpecies

    do while(associated(Species))

    !Particles (food) index number      
    Particles => Species%FirstParticles
    do while(associated(Particles))

    !water quality properties - organisms
    if (Particles%ID%Name .eq. 'phytoplankton') then

    if(Me%PropIndex%phyto .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%phyto= Me%Prop%IUB
    end if

    end if

    if (Particles%ID%Name .eq. 'zooplankton') then

    if(Me%PropIndex%zoo .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%zoo  = Me%Prop%IUB
    end if
    end if

    if (Particles%ID%Name .eq. 'ciliate') then

    if(Me%PropIndex%ciliate .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%ciliate            = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'bacteria') then

    if(Me%PropIndex%bacteria .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%bacteria           = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'cohesive sediment') then

    if(Me%PropIndex%sediments .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%sediments          = Me%Prop%IUB
    end if

    end if  

    !life and wq - diatoms
    if (Particles%ID%name .eq. 'diatoms') then

    if (Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then

    if(Me%PropIndex%diatoms .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%diatoms            = Me%Prop%IUB
    end if

    if(Particles%Silica .eq. 1)then

    if(Me%PropIndex%BioSilica .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%BioSilica          = Me%Prop%IUB
    end if 

    if(Me%PropIndex%DissSilica .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%DissSilica         = Me%Prop%IUB
    end if

    end if

    else

    !         if (GetPropertyIDNumber(trim(Particles%ID%name)//" carbon") .eq. GetPropertyIDNumber('diatoms carbon')) then
    if(Me%PropIndex%DiatomsC .eq. null_int)then

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%DiatomsC           = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%DiatomsN           = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%DiatomsP           = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%DiatomsChl         = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%DiatomsSi          = Me%Prop%IUB

    end if

    end if
    !model 

    end if
    !if is diatoms  

    !life properties - organisms
    if (Particles%ID%name .eq. 'autotrophic flagellates') then

    if(Me%PropIndex%Mix_FlagellateC .eq. null_int)then

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%Mix_FlagellateC    = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%Mix_FlagellateN    = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%Mix_FlagellateP    = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%Mix_FlagellateChl  = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'picoalgae') then

    if(Me%PropIndex%PicoalgaeC .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%PicoalgaeC         = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%PicoalgaeN         = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%PicoalgaeP         = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%PicoalgaeChl       = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'Flagellate') then

    if(Me%PropIndex%FlagellateC .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%FlagellateC        = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%FlagellateN        = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%FlagellateP        = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%FlagellateChl        = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'microzooplankton') then

    if(Me%PropIndex%MicrozooplanktonC .eq. null_int)then
    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%MicrozooplanktonC  = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%MicrozooplanktonN  = Me%Prop%IUB

    Me%Prop%IUB       = Me%Prop%IUB + 1
    Me%PropIndex%MicrozooplanktonP  = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'heterotrophic nanoflagellate') then

    if(Me%PropIndex%Het_NanoflagellateC .eq. null_int)then
    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%Het_NanoflagellateC  = Me%Prop%IUB

    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%Het_NanoflagellateN  = Me%Prop%IUB

    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%Het_NanoflagellateP  = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'mesozooplankton') then

    if(Me%PropIndex%MesozooplanktonC .eq. null_int)then
    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%MesozooplanktonC     = Me%Prop%IUB

    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%MesozooplanktonN     = Me%Prop%IUB

    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%MesozooplanktonP     = Me%Prop%IUB
    end if

    end if

    if (Particles%ID%name .eq. 'heterotrophic bacteria') then

    if(Me%PropIndex%Het_BacteriaC .eq. null_int)then
    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%Het_BacteriaC        = Me%Prop%IUB

    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%Het_BacteriaN        = Me%Prop%IUB

    Me%Prop%IUB         = Me%Prop%IUB + 1
    Me%PropIndex%Het_BacteriaP        = Me%Prop%IUB
    end if

    end if

    Particles => Particles%Next
    end do

    !Predator index number      
    Predator => Species%FirstPredator
    do while(associated(Predator))

    if (Predator%ID%name .eq. 'shrimp') then
    Me%Prop%IUB          = Me%Prop%IUB + 1
    Me%PropIndex%Shrimp  = Me%Prop%IUB
    end if

    if (Predator%ID%name .eq. 'crab') then
    Me%Prop%IUB          = Me%Prop%IUB + 1
    Me%PropIndex%Crab    = Me%Prop%IUB
    end if

    if (Predator%ID%name .eq. 'oystercatcher') then
    Me%Prop%IUB          = Me%Prop%IUB + 1
    Me%PropIndex%OysterCatcher         = Me%Prop%IUB
    end if

    if (Predator%ID%name .eq. 'eider duck') then
    Me%Prop%IUB          = Me%Prop%IUB + 1
    Me%PropIndex%EiderDuck             = Me%Prop%IUB
    end if

    if (Predator%ID%name .eq. 'herring gull') then
    Me%Prop%IUB          = Me%Prop%IUB + 1
    Me%PropIndex%HerringGull           = Me%Prop%IUB
    end if

    Predator => Predator%Next
    end do

    !Cohorts index number      
    Cohort => Species%FirstCohort
    do while(associated(Cohort))

    Me%Prop%IUB                 = Me%Prop%IUB + 1
    Cohort%StateIndex%M_V   = Me%Prop%IUB
    
    Me%Prop%IUB             = Me%Prop%IUB + 1
    Cohort%StateIndex%M_E   = Me%Prop%IUB

    Me%Prop%IUB             = Me%Prop%IUB + 1
    Cohort%StateIndex%M_H   = Me%Prop%IUB

    Me%Prop%IUB             = Me%Prop%IUB + 1
    Cohort%StateIndex%M_R   = Me%Prop%IUB

    Me%Prop%IUB             = Me%Prop%IUB + 1
    Cohort%StateIndex%L     = Me%Prop%IUB

    Me%Prop%IUB             = Me%Prop%IUB + 1
    Cohort%StateIndex%Age= Me%Prop%IUB

    Me%Prop%IUB             = Me%Prop%IUB + 1
    Cohort%StateIndex%Number           = Me%Prop%IUB

    Cohort => Cohort%Next
    end do

    Species => Species%Next
    end do

    end subroutine PropertyIndexNumber

    !-------------------------------------------------------------------------------

    subroutine ConstructPropertyList

    !Arguments-------------------------------------------------------------

    !Local-----------------------------------------------------------------
    type(T_Species)   , pointer       :: Species
    type(T_Cohort)    , pointer       :: Cohort
    type(T_Particles) , pointer       :: Particles
    type(T_Predator)  , pointer       :: Predator

    !Begin-----------------------------------------------------------------

    !Allocate new propertylist
    if (associated(Me%PropertyList)) deallocate(Me%PropertyList)

    allocate(Me%PropertyList(Me%Prop%ILB: Me%Prop%IUB))

    !life  properties
    if (Me%ComputeOptions%PelagicModel .eq. LifeModel) then

    Me%PropertyList(Me%PropIndex%POC) = POC_

    end if

    if(Me%ComputeOptions%Nitrogen)then
    Me%PropertyList(Me%PropIndex%AM)  = Ammonia_
    Me%PropertyList(Me%PropIndex%PON) = PON_
    end if

    if(Me%ComputeOptions%Phosphorus)then
    Me%PropertyList(Me%PropIndex%IP ) = Inorganic_Phosphorus_
    Me%PropertyList(Me%PropIndex%POP) = POP_
    end if


    Me%PropertyList(Me%PropIndex%CarbonDioxide)         = CarbonDioxide_

    Me%PropertyList(Me%PropIndex%Oxygen)  = Oxygen_

    !Include particles inside the Species in the property list 
    Me%nPropertiesFromBivalve = 0      
    Species => Me%FirstSpecies
    do while(associated(Species))

    Particles => Species%FirstParticles
    do while(associated(Particles))

    !wq properties
    !if (GetPropertyIDNumber(trim(Particles%ID%Name)) .eq. GetPropertyIDNumber('phytoplankton')) then
    if (Particles%ID%name .eq.'phytoplankton') then

    Me%PropertyList(Me%PropIndex%phyto)     = Phytoplankton_

    end if

    if (Particles%ID%name .eq.'zooplankton') then

    Me%PropertyList(Me%PropIndex%zoo)       = Zooplankton_

    end if

    if (Particles%ID%name .eq.'ciliate') then

    Me%PropertyList(Me%PropIndex%ciliate)   = Ciliate_

    end if

    if (Particles%ID%name .eq.'bacteria') then

    Me%PropertyList(Me%PropIndex%bacteria)  = Bacteria_

    end if

    if (Particles%ID%name .eq.'cohesive sediment') then

    Me%PropertyList(Me%PropIndex%sediments) = Cohesive_Sediment_

    end if


    !life and wq properties
    if (Particles%ID%Name .eq.'diatoms') then

    if (Me%ComputeOptions%PelagicModel .eq. LifeModel) then

    Me%PropertyList(Me%PropIndex%DiatomsC)      = Diatom_C_
    Me%PropertyList(Me%PropIndex%DiatomsN)      = Diatom_N_
    Me%PropertyList(Me%PropIndex%DiatomsP)      = Diatom_P_
    Me%PropertyList(Me%PropIndex%DiatomsChl)    = Diatom_Chl_
    Me%PropertyList(Me%PropIndex%DiatomsSi)     = Diatom_Si_
    Me%PropertyList(Me%PropIndex%BioSilica)     = BioSilica_
    Me%PropertyList(Me%PropIndex%DissSilica)    = Silicate_

    else

    Me%PropertyList(Me%PropIndex%diatoms)       = Diatoms_

    if(Particles%Silica .eq. 1)then

    Me%PropertyList(Me%PropIndex%BioSilica) = BioSilica_
    Me%PropertyList(Me%PropIndex%DissSilica)= Silicate_

    end if

    end if
    end if

    if (Particles%ID%Name .eq.'autotrophic flagellates') then

    Me%PropertyList(Me%PropIndex%Mix_FlagellateC)   = Mix_Flagellate_C_
    Me%PropertyList(Me%PropIndex%Mix_FlagellateN)   = Mix_Flagellate_N_
    Me%PropertyList(Me%PropIndex%Mix_FlagellateP)   = Mix_Flagellate_P_
    Me%PropertyList(Me%PropIndex%Mix_FlagellateChl) = Mix_Flagellate_Chl_

    end if

    if (Particles%ID%Name .eq.'picoalgae') then

    Me%PropertyList(Me%PropIndex%PicoalgaeC)        = Picoalgae_C_
    Me%PropertyList(Me%PropIndex%PicoalgaeN)        = Picoalgae_N_
    Me%PropertyList(Me%PropIndex%PicoalgaeP)        = Picoalgae_P_
    Me%PropertyList(Me%PropIndex%PicoalgaeChl)      = Picoalgae_Chl_

    end if

    if (Particles%ID%Name .eq.'flagellates') then

    Me%PropertyList(Me%PropIndex%FlagellateC)       = Flagellate_C_
    Me%PropertyList(Me%PropIndex%FlagellateN)       = Flagellate_N_
    Me%PropertyList(Me%PropIndex%FlagellateP)       = Flagellate_P_
    Me%PropertyList(Me%PropIndex%FlagellateChl)     = Flagellate_Chl_

    end if


    if (Particles%ID%Name .eq.'microzooplankton') then

    Me%PropertyList(Me%PropIndex%MicrozooplanktonC) = Microzooplankton_C_
    Me%PropertyList(Me%PropIndex%MicrozooplanktonN) = Microzooplankton_N_
    Me%PropertyList(Me%PropIndex%MicrozooplanktonP) = Microzooplankton_P_

    end if

    if (Particles%ID%Name .eq.'heterotrophic nanoflagellate') then

    Me%PropertyList(Me%PropIndex%Het_NanoflagellateC) = Het_Nanoflagellate_C_
    Me%PropertyList(Me%PropIndex%Het_NanoflagellateN) = Het_Nanoflagellate_N_
    Me%PropertyList(Me%PropIndex%Het_NanoflagellateP) = Het_Nanoflagellate_P_

    end if

    if (Particles%ID%Name .eq.'mesozooplankton') then

    Me%PropertyList(Me%PropIndex%MesozooplanktonC)    = Mesozooplankton_C_
    Me%PropertyList(Me%PropIndex%MesozooplanktonN)    = Mesozooplankton_N_
    Me%PropertyList(Me%PropIndex%MesozooplanktonP)    = Mesozooplankton_P_

    end if


    if (Particles%ID%Name .eq.'heterotrophic bacteria') then

    Me%PropertyList(Me%PropIndex%Het_BacteriaC)       = Het_Bacteria_C_
    Me%PropertyList(Me%PropIndex%Het_BacteriaN)       = Het_Bacteria_N_
    Me%PropertyList(Me%PropIndex%Het_BacteriaP)       = Het_Bacteria_P_

    end if

    Particles => Particles%Next
    end do

    !Include Predator in the property list        
    Predator => Species%FirstPredator
    do while(associated(Predator))

    if (Predator%ID%name .eq.'shrimp') then

    Me%PropertyList(Me%PropIndex%Shrimp)         = Shrimp_

    end if

    if (Predator%ID%name .eq.'crab') then

    Me%PropertyList(Me%PropIndex%Crab)           = Crab_

    end if

    if (Predator%ID%name .eq.'oystercatcher') then

    Me%PropertyList(Me%PropIndex%OysterCatcher)  = OysterCatcher_

    end if

    if (Predator%ID%name .eq.'eider duck') then

    Me%PropertyList(Me%PropIndex%EiderDuck)      = EiderDuck_

    end if

    if (Predator%ID%name .eq.'herring gull') then

    Me%PropertyList(Me%PropIndex%HerringGull)    = HerringGull_

    end if

    Predator => Predator%Next
    end do

    Cohort => Species%FirstCohort
    do while(associated(Cohort))

    Me%PropertyList(Cohort%StateIndex%M_V)     = &
    GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" structure")   
    Me%PropertyList(Cohort%StateIndex%M_E)   = &
    GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" reserves")
    Me%PropertyList(Cohort%StateIndex%M_H) = &
    GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" maturity")
    Me%PropertyList(Cohort%StateIndex%M_R)    = &
    GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" reproduction")
    Me%PropertyList(Cohort%StateIndex%L)    = &
    GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" length")
    Me%PropertyList(Cohort%StateIndex%Age)    = &
    GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" age")
    Me%PropertyList(Cohort%StateIndex%Number)    = &
    GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" number")
    
    Me%nPropertiesFromBivalve = Me%nPropertiesFromBivalve + 7

    Cohort => Cohort%Next
    end do

    Species => Species%Next
    end do

    end subroutine ConstructPropertyList

    !-------------------------------------------------------------------------------    

    subroutine AllocateAndInitializeByIndex (Index)

        !Arguments-------------------------------------------------------------

        !Local-----------------------------------------------------------------
        type(T_Species)         , pointer           :: Species
        type(T_Cohort)          , pointer           :: Cohort
        integer                                     :: Index
        integer                                     :: Number
        integer                                     :: Shrimp, Crab, OysterCatcher
        integer                                     :: EiderDuck, HerringGull

        !Begin-----------------------------------------------------------------
        
        Shrimp        = Me%PropIndex%Shrimp
        Crab          = Me%PropIndex%Crab
        OysterCatcher = Me%PropIndex%OysterCatcher
        EiderDuck     = Me%PropIndex%EiderDuck
        HerringGull   = Me%PropIndex%HerringGull

        Species => Me%FirstSpecies
        do while(associated(Species))

            Species%PopulationProcesses%TNStartTimeStep = 0.0
            
            Cohort => Species%FirstCohort
            do while(associated(Cohort))
            
                Number = Cohort%StateIndex%Number 
            
                !in the begining of the simulation, the cohort is always alive
                Cohort%Dead = 0

                Cohort%Processes%DeathByAge                   = 0.0
                Cohort%Processes%DeathByOxygen                = 0.0
                Cohort%Processes%DeathByStarvation            = 0.0
                Cohort%Processes%DeathByNatural               = 0.0
                Cohort%Processes%PredationByShrimps           = 0.0
                Cohort%Processes%PredationByCrabs             = 0.0
                Cohort%Processes%PredationByOysterCatchers    = 0.0
                Cohort%Processes%PredationByEiderDucks        = 0.0
                Cohort%Processes%PredationByHerringGull       = 0.0
                Cohort%Processes%DeathByLowNumbers            = 0.0
                
                
                Species%PopulationProcesses%TNStartTimeStep =  Species%PopulationProcesses%TNStartTimeStep + &
                                                    Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index)

                if(.not. associated(Cohort%FeedingOn))then

                    allocate(Cohort%FeedingOn(Species%nParticles, 3)) !store values, Col = Filtered ingested assimilated 

                end if
                
                !Convert the mussels organisms density to /m3
                if (Me%DensityUnits .eq. 0)  then !units for mussel density is in /m2
                
                    Me%ExternalVar%Mass(Number,Index) = Me%ExternalVar%Mass(Number,Index)   * &
                                                        Me%ExternalVar%CellArea(Index)      * &
                                                        1/Me%ExternalVar%CellVolume(Index)
                end if
                
                Cohort => Cohort%Next

            end do
                                    
            Species => Species%Next

        end do
        
        !Convert the predators organisms density to /m3
        if(Shrimp .ne. null_int)then

            Me%ExternalVar%Mass(Shrimp,Index) = Me%ExternalVar%Mass(Shrimp,Index)    * &
                                                Me%ExternalVar%CellArea(Index)       * &
                                                1/Me%ExternalVar%CellVolume(Index)
        end if

        if(Crab .ne. null_int)then

            Me%ExternalVar%Mass(Crab,Index) = Me%ExternalVar%Mass(Crab,Index)        * &
                                              Me%ExternalVar%CellArea(Index)         * &
                                              1/Me%ExternalVar%CellVolume(Index)
        end if
        
        if(Me%PropIndex%Crab .ne. null_int)then

            Me%ExternalVar%Mass(OysterCatcher,Index) = Me%ExternalVar%Mass(OysterCatcher,Index) * &
                                                       Me%ExternalVar%CellArea(Index)           * &
                                                       1/Me%ExternalVar%CellVolume(Index)
        end if

        if(Me%PropIndex%Crab .ne. null_int)then

            Me%ExternalVar%Mass(EiderDuck,Index) = Me%ExternalVar%Mass(EiderDuck,Index)        * &
                                                   Me%ExternalVar%CellArea(Index)              * &
                                                   1/Me%ExternalVar%CellVolume(Index)
        end if

    end subroutine AllocateAndInitializeByIndex

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    !SELECTOR SELECTOR SELECTOR SELECTOR SELECTOR SELECTOR SELECTOR SELECTOR SELECTO

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    subroutine GetBivalvePropertyList(Bivalve_ID, PropertyList, STAT)

    !Arguments-------------------------------------------------------------
    integer       :: Bivalve_ID
    integer, dimension(:), pointer            :: PropertyList
    integer, optional, intent(OUT)            :: STAT

    !External--------------------------------------------------------------
    integer       :: ready_

    !Local-----------------------------------------------------------------
    integer       :: STAT_

    !----------------------------------------------------------------------

    STAT_ = UNKNOWN_

    call Ready(Bivalve_ID, ready_)    

    if1 :   if ((ready_ .EQ. IDLE_ERR_     ) .OR.     &
    (ready_ .EQ. READ_LOCK_ERR_)) then

    call Read_Lock(mBivalve_, Me%InstanceID)

    PropertyList => Me%PropertyList

    STAT_ = SUCCESS_
    else 
    STAT_ = ready_
    end if if1

    if (present(STAT))STAT = STAT_

    end subroutine GetBivalvePropertyList

    !--------------------------------------------------------------------------

    subroutine GetDTBivalve(Bivalve_ID, DTDay, DTSecond, STAT)

    !Arguments-------------------------------------------------------------
    integer :: Bivalve_ID
    real,    optional, intent(OUT)      :: DTDay
    real,    optional, intent(OUT)      :: DTSecond
    integer, optional, intent(OUT)      :: STAT

    !External--------------------------------------------------------------
    integer :: ready_

    !Local-----------------------------------------------------------------
    integer :: STAT_

    !----------------------------------------------------------------------

    STAT_ = UNKNOWN_

    call Ready(Bivalve_ID, ready_)    

    cd1 :   if ((ready_ .EQ. IDLE_ERR_     ) .OR.     &
    (ready_ .EQ. READ_LOCK_ERR_)) then

    if (present(DTDay   )) DTDay    = Me%DTDay
    if (present(DTSecond)) DTSecond = Me%DT

    STAT_ = SUCCESS_
    else 
    STAT_ = ready_
    end if cd1

    if (present(STAT))STAT = STAT_

    end subroutine GetDTBivalve

    !--------------------------------------------------------------------------

    subroutine GetBivalveSize(Bivalve_ID, PropLB, PropUB, STAT)

        !Arguments-------------------------------------------------------------
        integer :: Bivalve_ID
        integer, optional, intent(OUT)      :: PropLB,PropUB
        integer, optional, intent(OUT)      :: STAT

        !External--------------------------------------------------------------
        integer :: ready_

        !Local-----------------------------------------------------------------
        integer :: STAT_

        !----------------------------------------------------------------------

        STAT_ = UNKNOWN_

        call Ready(Bivalve_ID, ready_)    

cd1 :   if ((ready_ .EQ. IDLE_ERR_     ) .OR.     &
            (ready_ .EQ. READ_LOCK_ERR_)) then

            if (present(PropLB   )) PropLB    = Me%Prop%ILB
            if (present(PropUB   )) PropUB    = Me%Prop%IUB

            STAT_ = SUCCESS_
        else 
            STAT_ = ready_
        end if cd1

        if (present(STAT))STAT = STAT_

    end subroutine GetBivalveSize

    !--------------------------------------------------------------------------

    subroutine GetBivalvePropIndex (Bivalve_ID, PropertyIDNumber, PropertyIndex, STAT)

    !Arguments-------------------------------------------------------------
    integer :: Bivalve_ID
    integer,           intent(IN )      :: PropertyIDNumber
    integer,           intent(OUT)      :: PropertyIndex
    integer, optional, intent(OUT)      :: STAT

    !External--------------------------------------------------------------
    integer :: ready_

    !Local-----------------------------------------------------------------
    integer :: STAT_, CurrentIndex
    logical :: found

    !----------------------------------------------------------------------

    STAT_ = UNKNOWN_

    call Ready(Bivalve_ID, ready_)    

    cd1 :   if ((ready_ .EQ. IDLE_ERR_     ) .OR.     &
    (ready_ .EQ. READ_LOCK_ERR_)) then

    found = .false.
    do CurrentIndex = Me%Prop%ILB,Me%Prop%IUB

    if (PropertyIDNumber.eq. Me%PropertyList(CurrentIndex))then
    PropertyIndex = CurrentIndex
    found = .true.
    exit
    end if

    end do

    if(.not. found)then
    STAT_ = NOT_FOUND_ERR_
    else
    STAT_ = SUCCESS_
    endif

    else 
    STAT_ = ready_
    end if cd1

    if (present(STAT))STAT = STAT_

    end subroutine GetBivalvePropIndex

    !--------------------------------------------------------------------------

    subroutine GetBivalveListDeadIDS(BivalveID, ListDeadIDS, STAT)

        !Arguments-------------------------------------------------------------
        integer                             :: BivalveID
        integer, dimension(:), pointer      :: ListDeadIDS
        integer, optional, intent(OUT)      :: STAT

        !Local-----------------------------------------------------------------
        integer :: STAT_
        integer :: ready_

        !----------------------------------------------------------------------

        STAT_ = UNKNOWN_

        call Ready(BivalveID, ready_)    

if1 :       if ((ready_ .EQ. IDLE_ERR_     ) .OR. (ready_ .EQ. READ_LOCK_ERR_)) then

                call Read_Lock(mBivalve_, Me%InstanceID)

                ListDeadIDS => Me%ListDeadIDs(:)

                STAT_ = SUCCESS_
            else 
                STAT_ = ready_
            end if if1

        if (present(STAT)) STAT = STAT_

    end subroutine GetBivalveListDeadIDS

    !--------------------------------------------------------------------------

    subroutine GetBivalveNewborns(BivalveID, ListNewbornsIDs, MatrixNewborns, STAT)

        !Arguments-------------------------------------------------------------
        integer                               :: BivalveID
        integer, dimension(:), pointer        :: ListNewbornsIDs
        real,    dimension(:,:), pointer      :: MatrixNewborns
        integer, optional, intent(OUT)        :: STAT

        !Local-----------------------------------------------------------------
        integer                               :: STAT_
        integer                               :: ready_

        !----------------------------------------------------------------------

        STAT_ = UNKNOWN_

        call Ready(BivalveID, ready_)    

if1 :   if ((ready_ .EQ. IDLE_ERR_     ) .OR.  (ready_ .EQ. READ_LOCK_ERR_)) then

            call Read_Lock(mBivalve_, Me%InstanceID)
            ListNewbornsIDs => Me%ListNewbornsIDs(:)

            call Read_Lock(mBivalve_, Me%InstanceID)
            MatrixNewborns => Me%MatrixNewborns(:,:)

            STAT_ = SUCCESS_
        else 
            STAT_ = ready_
        end if if1

        if (present(STAT)) STAT = STAT_

    end subroutine GetBivalveNewborns
    
    !--------------------------------------------------------------------------

    subroutine GetBivalveNewBornParameters(Bivalve_ID, SpeciesIDNumber, M_V0, M_E0, M_H0, L_0, STAT)

        !Arguments-------------------------------------------------------------
        integer                             :: Bivalve_ID
        integer,           intent(IN)       :: SpeciesIDNumber
        real,    optional, intent(OUT)      :: M_V0, M_E0, M_H0 , L_0
        integer, optional, intent(OUT)      :: STAT

        !Local-----------------------------------------------------------------
        integer :: STAT_
        integer :: ready_      
        type(T_Species),  pointer           :: Species

        !----------------------------------------------------------------------

        STAT_ = UNKNOWN_

        call Ready(Bivalve_ID, ready_)    

cd1 :   if ((ready_ .EQ. IDLE_ERR_     ) .OR. (ready_ .EQ. READ_LOCK_ERR_)) then
        
            Species => Me%FirstSpecies
            do while(associated(Species))

                if(Species%ID%IDNumber == SpeciesIDNumber)then

                    if(present(M_V0)) M_V0 = Species%IndividualParameters%MVb
                    if(present(M_E0)) M_E0 = Species%IndividualParameters%MEb
                    if(present(M_H0)) M_H0 = Species%IndividualParameters%MHb
                    if(present(L_0 )) L_0  = Species%IndividualParameters%Lb

                endif

                Species => Species%Next
            end do 

            STAT_ = SUCCESS_
        else 
            STAT_ = ready_
        end if cd1

        if (present(STAT))STAT = STAT_

    end subroutine GetBivalveNewBornParameters

     !--------------------------------------------------------------------------

    subroutine GetBivalveOtherParameters(Bivalve_ID, SpeciesIDNumber, MinObsLength, STAT)

        !Arguments-------------------------------------------------------------
        integer                             :: Bivalve_ID
        integer,           intent(IN)       :: SpeciesIDNumber
        real,    optional, intent(OUT)      :: MinObsLength
        integer, optional, intent(OUT)      :: STAT

        !Local-----------------------------------------------------------------
        integer                             :: STAT_
        integer                             :: ready_      
        type(T_Species),  pointer           :: Species

        !----------------------------------------------------------------------

        STAT_ = UNKNOWN_

        call Ready(Bivalve_ID, ready_)    

cd1 :   if ((ready_ .EQ. IDLE_ERR_     ) .OR. (ready_ .EQ. READ_LOCK_ERR_)) then
        
            Species => Me%FirstSpecies
            do while(associated(Species))

                if(Species%ID%IDNumber == SpeciesIDNumber)then

                    if(present(MinObsLength)) MinObsLength = Species%MinObsLength

                endif

                Species => Species%Next
            end do 

            STAT_ = SUCCESS_
        else 
            STAT_ = ready_
        end if cd1

        if (present(STAT))STAT = STAT_

    end subroutine GetBivalveOtherParameters

   !--------------------------------------------------------------------------

    subroutine UnGetBivalve1D_I(BivalveID, Array, STAT)

    !Arguments-------------------------------------------------------------
    integer             :: BivalveID
    integer, dimension(:), pointer    :: Array
    integer, intent(OUT), optional    :: STAT

    !Local-----------------------------------------------------------------
    integer             :: STAT_, ready_

    !----------------------------------------------------------------------

    STAT_ = UNKNOWN_

    call Ready(BivalveID, ready_)

    if (ready_ .EQ. READ_LOCK_ERR_) then

    nullify(Array)
    call Read_Unlock(mBivalve_, Me%InstanceID, "UnGetBivalve1D_I")

    STAT_ = SUCCESS_
    else 
    STAT_ = ready_
    end if

    if (present(STAT)) STAT = STAT_

    end subroutine UnGetBivalve1D_I

    !--------------------------------------------------------------------------

    subroutine UnGetBivalve2D_R4(BivalveID, Array, STAT)

    !Arguments-------------------------------------------------------------
    integer                           :: BivalveID
    real, dimension(:,:), pointer     :: Array
    integer, intent(OUT), optional    :: STAT

    !Local-----------------------------------------------------------------
    integer             :: STAT_, ready_

    !----------------------------------------------------------------------

    STAT_ = UNKNOWN_

    call Ready(BivalveID, ready_)

    if (ready_ .EQ. READ_LOCK_ERR_) then

    nullify(Array)
    call Read_Unlock(mBivalve_, Me%InstanceID, "UnGetBivalve2D_R4")

    STAT_ = SUCCESS_
    else 
    STAT_ = ready_
    end if

    if (present(STAT)) STAT = STAT_

    end subroutine UnGetBivalve2D_R4

    !--------------------------------------------------------------------------

    integer function SearchPropIndex (PropIDNumber)

    !Arguments-------------------------------------------------------------
    integer,  intent(IN )           :: PropIDNumber
    !Local-----------------------------------------------------------------
    integer           :: CurrentIndex

    !----------------------------------------------------------------------

    SearchPropIndex = UNKNOWN_

    do CurrentIndex = Me%Prop%ILB, Me%Prop%IUB

    if (PropIDNumber == Me%PropertyList(CurrentIndex))then
    SearchPropIndex = CurrentIndex
    exit
    end if

    end do

    end function SearchPropIndex


    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    !MODIFIER MODIFIER MODIFIER MODIFIER MODIFIER MODIFIER MODIFIER MODIFIER MODIFIE

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    subroutine ModifyBivalve(ObjBivalveID         , &
                             Temperature          , &
                             Salinity             , & 
                             Mass                 , &
                             ArraySize            , &
                             OpenPoints           , &
                             WaterVolumeIN        , &
                             CellAreaIN           , &
                             STAT)
        !Arguments------------------------------------------------------------------
        integer                                         :: ObjBivalveID
        real,    pointer, dimension(:  )                :: Temperature
        real,    pointer, dimension(:  )                :: Salinity
        real,    pointer, dimension(:,:)                :: Mass
        type(T_Size1D)                                  :: ArraySize
        integer, pointer, dimension(:  )                :: OpenPoints
        real(8), pointer, dimension(:  )                :: WaterVolumeIN
        real, pointer, dimension(:  )                   :: CellAreaIN
        integer, intent(OUT), optional                  :: STAT
       
        !Local----------------------------------------------------------------------
        integer                                         :: STAT_, ready_
        integer                                         :: Index
        !integer                                         :: STAT_CALL

        !---------------------------------------------------------------------------

        STAT_ = UNKNOWN_
        
        Me%Array%ILB = ArraySize%ILB
        Me%Array%IUB = ArraySize%IUB

        call Ready(ObjBivalveID, ready_)

        if (ready_ .EQ. IDLE_ERR_) then

            Me%ExternalVar%Temperature  => Temperature
            if (.not. associated(Me%ExternalVar%Temperature))       &
            stop 'ModifyBivalve - ModuleBivalve - ERR01'

            Me%ExternalVar%Salinity     => Salinity
            if (.not. associated(Me%ExternalVar%Salinity))          &   
            stop 'ModifyBivalve - ModuleBivalve - ERR02'

            Me%ExternalVar%Mass         => Mass   !mg/l (g/m3)
            if (.not. associated(Me%ExternalVar%Mass))              &
            stop 'ModifyBivalve - ModuleBivalve - ERR03'
            
            Me%ExternalVar%CellVolume  => WaterVolumeIN
            if (.not. associated(Me%ExternalVar%CellVolume))        &
            stop 'ModifyBivalve - ModuleBivalve - ERR04'

            Me%ExternalVar%CellArea  => CellAreaIN
            if (.not. associated(Me%ExternalVar%CellArea))          &
            stop 'ModifyBivalve - ModuleBivalve - ERR05'

            call AllocateAndInitializeByTimeStep

            do Index = Me%Array%ILB, Me%Array%IUB

                call ComputeBivalve (Index, OpenPoints(Index))

            enddo
            
            call UpdateListDeadAndNewBornIDs
                        
            STAT_ = SUCCESS_
        else 
            STAT_ = ready_
        end if

        if (present(STAT)) STAT = STAT_

    end subroutine ModifyBivalve

    !-------------------------------------------------------------------------------    

    subroutine AllocateAndInitializeByTimeStep

        !Arguments-------------------------------------------------------------

        !Local-----------------------------------------------------------------
        type(T_Species)         , pointer           :: Species
        type(T_Cohort)          , pointer           :: Cohort
        integer                                     :: TotalNumberIndex

        !Begin-----------------------------------------------------------------

        Species  => Me%FirstSpecies
d1:     do while (associated(Species))

            Species%NewbornCohort = .false. 
            
            Cohort  => Species%FirstCohort
d2:         do while (associated(Cohort))

                Cohort%GlobalDeath = 1

                Cohort  => Cohort%Next  
            end do  d2        

            Species  => Species%Next  
        enddo  d1

        TotalNumberIndex = Me%Array%IUB
                
        !List of Cohorts/Properties IDs from cohorts that died in this time step (died in all cells)
        if(associated(Me%ListDeadIDs)) deallocate (Me%ListDeadIDs)
        allocate(Me%ListDeadIDs(Me%nPropertiesFromBivalve))
        Me%ListDeadIDs = 0
        
        Me%nLastDeadID = 0
        
        !List of Species IDs that will have Newborns in the next time step
        if(associated(Me%ListNewbornsIDs)) deallocate (Me%ListNewbornsIDs)
        allocate(Me%ListNewbornsIDs(Me%nSpecies))
        Me%ListNewbornsIDs = 0
        
        Me%nLastNewbornsID = 0

        !newborns for each species in each index
        if(associated(Me%MatrixNewborns )) deallocate (Me%MatrixNewborns)
        allocate(Me%MatrixNewborns(Me%nSpecies, TotalNumberIndex+1))
        
        Me%MatrixNewborns = 0
        
    end subroutine AllocateAndInitializeByTimeStep

    !--------------------------------------------------------------------------

    subroutine ComputeBivalve(Index, CheckIfOpenPoint)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)           :: Index
        integer, intent(IN)           :: CheckIfOpenPoint

        !Local-----------------------------------------------------------------

        !Begin-----------------------------------------------------------------

        call AllocateAndInitializeByIndex (Index)

        call ComputeIndividualProcesses (Index, CheckIfOpenPoint)

        call ComputeNaturalMortality (Index)

        call ComputePredation (Index, CheckIfOpenPoint)

        call ComputePopulationVariables (Index)
        
        if (Me%OutputON) call WriteOutput (Index)
        
        call UpdateCohortState
        
        call RestoreUnits (Index)

    end subroutine ComputeBivalve

    !--------------------------------------------------------------------------

    subroutine ComputeIndividualProcesses (Index, CheckIfOpenPoint)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)           :: Index
        integer, intent(IN)           :: CheckIfOpenPoint

        !Local-----------------------------------------------------------------
        type(T_Species)    , pointer :: Species
        type(T_Cohort)     , pointer :: Cohort
        integer        :: O   

        !Begin-----------------------------------------------------------------

        O  = Me%PropIndex%Oxygen

        !if (Me%ExternalVar%Mass(O, Index) .gt. 0.0) then !Bivalve can survive         

            Species => Me%FirstSpecies
d1:         do while(associated(Species))

                Species%PopulationProcesses%nNewborns = 0

                call ComputeChemicalIndices    (Index, Species)

                call ComputeAuxiliarParameters (Index, Species)

                call ComputeBivalveCondition   (Index, Species)

                Species => Species%Next

            end do d1

            call ComputeFeedingProcesses (Index, CheckIfOpenPoint) !for all species

            Species => Me%FirstSpecies
    d2:     do while(associated(Species))

                Cohort => Species%FirstCohort
    d3:         do while(associated(Cohort))

                    call ComputeSomaticMaintenance (Species, Cohort)

                    call ComputeMobilization       (Species, Cohort)

                    call ComputeReservesDynamics   (Index, Cohort)

                    call ComputeStructureDynamics  (Index, Species, Cohort)

                    call ComputeMaturity           (Index, Species, Cohort)

                    call ComputeLengthAgeDynamics  (Index, Species, Cohort)

                    if (Cohort%Dead .eq. 0) then

                    call ComputeSpawning (Index, Species, Cohort)

                    call ComputeReproductionDynamics (Index, Cohort)

                    call ComputeInorganicFluxes (Index, Species, Cohort)

                    end  if

                    Cohort => Cohort%Next
                end do d3

                if ((Species%Population) .and. (Species%PopulationProcesses%nNewborns .gt. 0.0 )) then 
                !if it is not population then new borns will be ignored
                
                    Species%NewbornCohort = .true.
                    
                    !Add the SpeciesID to the list of Species ID with new borns in t henext time step   
                    Me%MatrixNewborns(Species%ID%ID,1) = Species%ID%IDNumber
                    Me%MatrixNewborns(Species%ID%ID,Index+1) = Species%PopulationProcesses%nNewborns
                    
                end if 

            Species => Species%Next
            end do d2

!        else !no oxygen in the system
!
!            Species => Me%FirstSpecies
!d4:         do while(associated(Species))
!
!                Cohort => Species%FirstCohort
!d5:             do while(associated(Cohort))
!
!                    if (Cohort%Dead .eq. 0 ) then
!
!                        Cohort%Processes%DeathByOxygen = Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) / &
!                        Me%DTDay ! They will all die
!                                                
!                        call ImposeCohortDeath (Index, Species, Cohort) !sets all the processes to zero and convert mass to OM     
!
!!                        if (Species%nCohorts .eq. Me%nListDeadIDs) then
!                        if ((Species%nCohorts .eq. 1) .and. (Cohort%Dead .eq. 1 )) then                        
!                        !if the last cohort in the population                          
!
!                            Species%PopulationProcesses%LastCauseofDeath(2) = Cohort%Processes%DeathByOxygen
!                            Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
!                            
!                        end if
!                        
!                        !set the state of the dead cohort to zero
!                        Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)      = 0.0
!                        Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) = 0.0
!
!                    end if
!
!                    Cohort => Cohort%Next
!                end do d5
!
!            Species => Species%Next
!            end do d4
!
!        end if

    end subroutine ComputeIndividualProcesses

    !--------------------------------------------------------------------------

    subroutine ComputeChemicalIndices (Index, Species)

    !Arguments-------------------------------------------------------------
    integer, intent(IN)           :: Index
    type(T_Species)      , pointer:: Species

    !Local-----------------------------------------------------------------
    type(T_Particles)    , pointer:: Particles
    integer         :: PropertyIndexC, PropertyIndexN
    integer         :: PropertyIndexP, PropertyIndexChl
    integer         :: PropertyIndexSi
    real            :: C_AtomicMass, H_AtomicMass,O_AtomicMass 
    real            :: P_AtomicMass, N_AtomicMass

    !Begin-----------------------------------------------------------------


    C_AtomicMass  = Species%AuxiliarParameters%C_AtomicMass        
    H_AtomicMass  = Species%AuxiliarParameters%H_AtomicMass        
    O_AtomicMass  = Species%AuxiliarParameters%O_AtomicMass        
    P_AtomicMass  = Species%AuxiliarParameters%P_AtomicMass        
    N_AtomicMass  = Species%AuxiliarParameters%N_AtomicMass        

    Particles => Species%FirstParticles
    d1:     do while(associated(Particles))

    if (Particles%Organic .eq. 1) then

    if (Particles%RatioVariable .eq. 1) then
    !compute actual ratios based on mass values

    if (Particles%ID%Name .eq. 'particulate organic matter') then
    PropertyIndexC   = SearchPropIndex(GetPropertyIDNumber("particulate organic carbon"))
    PropertyIndexN   = SearchPropIndex(GetPropertyIDNumber("particulate organic nitrogen"))
    PropertyIndexP   = SearchPropIndex(GetPropertyIDNumber("particulate organic phosphorus"))
    else
    PropertyIndexC   = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" carbon")))
    PropertyIndexN   = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" nitrogen")))
    PropertyIndexP   = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" phosphorus")))
    end if

    !g/g
    Particles%Ratios%NC_Ratio   = Me%ExternalVar%Mass(PropertyIndexN,Index) /             &
    Me%ExternalVar%Mass(PropertyIndexC,Index)

    Particles%Ratios%PC_Ratio   = Me%ExternalVar%Mass(PropertyIndexP,Index) /             &
    Me%ExternalVar%Mass(PropertyIndexC,Index)

    if(Particles%Silica .eq. 1)then          

    PropertyIndexSi  = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" silica")))
    Particles%Ratios%SiC_Ratio   = Me%ExternalVar%Mass(PropertyIndexSi,Index) /       &
    Me%ExternalVar%Mass(PropertyIndexC,Index)

    end if

    if ((Particles%ID%Name .eq. 'diatoms') .or. (Particles%ID%Name .eq. 'autotrophic flagellates') .or. &
    (Particles%ID%Name .eq. 'picoalgae') .or. (Particles%ID%Name .eq. 'flagellates')) then 

    PropertyIndexChl = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" chlorophyll")))

    Particles%Ratios%ChlC_Ratio = Me%ExternalVar%Mass(PropertyIndexChl,Index) /       &
    Me%ExternalVar%Mass(PropertyIndexC,Index)

    end if

    end if 

    Particles%Composition%nC = 1

    Particles%Composition%nH = (Particles%Ratios%HC_Ratio / H_AtomicMass) * C_AtomicMass

    Particles%Composition%nO = (Particles%Ratios%OC_Ratio / O_AtomicMass) * C_AtomicMass

    Particles%Composition%nN = (Particles%Ratios%NC_Ratio / N_AtomicMass) * C_AtomicMass

    Particles%Composition%nP = (Particles%Ratios%PC_Ratio / P_AtomicMass) * C_AtomicMass

    else

    Particles%Composition%nC = 0.0

    Particles%Composition%nH = 0.0

    Particles%Composition%nO = 0.0

    Particles%Composition%nN = 0.0

    Particles%Composition%nP = 0.0

    end if

    Particles => Particles%Next

    end do d1

    end subroutine ComputeChemicalIndices

    !--------------------------------------------------------------------------

    subroutine ComputeAuxiliarParameters (Index, Species)

    !Arguments-------------------------------------------------------------
    integer, intent(IN)           :: Index
    type(T_Species),    pointer   :: Species

    !Local-----------------------------------------------------------------
    real            :: Tref, TA, TL, TH, TAL, TAH, T
    real            :: pM, EG, mu_E, d_V
    real            :: PAM_FIX, delta_M, kappa

    !Begin-----------------------------------------------------------------

    Tref    = Species%IndividualParameters%Tref
    TA      = Species%IndividualParameters%TA
    TL      = Species%IndividualParameters%TL
    TH      = Species%IndividualParameters%TH
    TAL     = Species%IndividualParameters%TAL
    TAH     = Species%IndividualParameters%TAH
    pM      = Species%IndividualParameters%pM   
    EG      = Species%IndividualParameters%EG     
    mu_E    = Species%IndividualParameters%mu_E
    d_V     = Species%IndividualParameters%d_V
    PAM_FIX = Species%IndividualParameters%PAM_FIX
    delta_M = Species%IndividualParameters%delta_M
    kappa   = Species%IndividualParameters%kappa

    !Temperature Correction factor

    !K, Actual Temperature, oC to K
    T = Me%ExternalVar%Temperature(index) + 273


    if (Species%IndividualParameters%SIMPLE_TEMP .eq. 0.0) then
    Species%AuxiliarParameters%TempCorrection  = exp(TA/Tref-TA/T) *     &
    (1.0 + exp(TAL/Tref - TAL/TL) + exp(TAH/TH-TAH/Tref))/   &
    (1.0 + exp(TAL/T - TAL/TL) + exp(TAH/TH-TAH/T))
    else            
    Species%AuxiliarParameters%TempCorrection  = exp(TA/Tref-TA/T) 
    end if


    !WE, gDW/molC , ash free dry weight to carbon convertion factor for bivalve reserve  
    Species%AuxiliarParameters%WE  =  Species%SpeciesComposition%ReservesComposition%nC *  &
    Species%AuxiliarParameters%C_AtomicMass            + &
    Species%SpeciesComposition%ReservesComposition%nH *  &
    Species%AuxiliarParameters%H_AtomicMass            + &
    Species%SpeciesComposition%ReservesComposition%nO *  &
    Species%AuxiliarParameters%O_AtomicMass            + &
    Species%SpeciesComposition%ReservesComposition%nN *  &
    Species%AuxiliarParameters%N_AtomicMass            + &
    Species%SpeciesComposition%ReservesComposition%nP *  &
    Species%AuxiliarParameters%P_AtomicMass   

    !WV, gDW/molC , ash free dry weight to carbon convertion factor for bivalve structure  
    Species%AuxiliarParameters%WV = Species%AuxiliarParameters%WE

    !Mv, molC(struc)/cm3, volume specific structural mass
    Species%AuxiliarParameters%Mv  = d_V / Species%AuxiliarParameters%WV

    !MHb, molC, Maturity threshold for birth
    Species%AuxiliarParameters%MHb  = Species%IndividualParameters%EHb / mu_E 

    !MHp, molC, Maturity threshold for puberty
    Species%AuxiliarParameters%MHp  = Species%IndividualParameters%EHp / mu_E 

    !y_VE, molC(struc)/molC(reser), yield of structure on reserves
    Species%AuxiliarParameters%y_VE = Species%AuxiliarParameters%Mv * mu_E / EG 

    !kM, d-1, somatic maintenance rate coefficient
    Species%AuxiliarParameters%kM = pM / EG         

    !kJ, d-1, maturity maintenance rate coefficient
    Species%AuxiliarParameters%kJ  = Species%AuxiliarParameters%kM

    !Lm, cm, maximum length of the species
    Species%AuxiliarParameters%Lm  = ((kappa * PAM_FIX) / pM) / delta_M 

    end subroutine ComputeAuxiliarParameters

    !--------------------------------------------------------------------------

    subroutine ComputeBivalveCondition (Index, Species)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)           :: Index
        type(T_Species),    pointer   :: Species

        !Local-----------------------------------------------------------------
        type(T_Cohort),     pointer   :: Cohort
        integer         :: L, M_V, M_E, M_R

        !Begin-----------------------------------------------------------------

        Cohort => Species%FirstCohort
        d1:     do while(associated(Cohort))

            L   = Cohort%StateIndex%L
            M_V = Cohort%StateIndex%M_V
            M_E = Cohort%StateIndex%M_E
            M_R = Cohort%StateIndex%M_R

            !Vol, cm3, Structural volume of the organism
            Cohort%BivalveCondition%Vol  = Me%ExternalVar%Mass(M_V, Index) / Species%AuxiliarParameters%Mv

            !E, molC(reserves)/cm3(deb), reserve density
            if (Cohort%BivalveCondition%Vol .eq. 0.0 ) then
            
                Cohort%BivalveCondition%E   = 0.0
                
                Cohort%BivalveCondition%GSR = 0.0
                
            else
                Cohort%BivalveCondition%E = Me%ExternalVar%Mass(M_E, Index) / Cohort%BivalveCondition%Vol

                !GSR, molC(gam)/molC(total), fraction of gametes in the organism
                Cohort%BivalveCondition%GSR = Me%ExternalVar%Mass(M_R, Index)                / &
                                            ( Me%ExternalVar%Mass(M_V, Index)                + &
                                              Me%ExternalVar%Mass(M_E, Index)                + &
                                              Me%ExternalVar%Mass(M_R, Index) )
            end if


            !DW, mgDW, organism total dry weight, 1e3 * (molC * gdw/molC)
            Cohort%BivalveCondition%DW = 1e3                                                                    * &
                                        ( Me%ExternalVar%Mass(M_V, Index) * Species%AuxiliarParameters%WV       + &
                                        (Me%ExternalVar%Mass(M_E, Index) + Me%ExternalVar%Mass(M_R, Index))     * &
                                        Species%AuxiliarParameters%WE )    

            !TotalmolC, molC, organism total molC
            Cohort%BivalveCondition%TotalmolC = Me%ExternalVar%Mass(M_V, Index)                                 + &
                                            Me%ExternalVar%Mass(M_E, Index)                                     + &
                                            Me%ExternalVar%Mass(M_R, Index)

            !TotalmolN, molN, organism total molN
            Cohort%BivalveCondition%TotalmolN = Me%ExternalVar%Mass(M_V, Index)                                 * &
                                            Species%SpeciesComposition%StructureComposition%nN                  + &
                                            (Me%ExternalVar%Mass(M_E, Index) + Me%ExternalVar%Mass(M_R, Index)) * &
                                            Species%SpeciesComposition%ReservesComposition%nN     


            !TotalmolP, molP, organism total molP
            Cohort%BivalveCondition%TotalmolP = Me%ExternalVar%Mass(M_V, Index)                                 * &
                                            Species%SpeciesComposition%StructureComposition%nP                  + &
                                            (Me%ExternalVar%Mass(M_E, Index) + Me%ExternalVar%Mass(M_R, Index)) * &
                                            Species%SpeciesComposition%ReservesComposition%nP     


            Cohort => Cohort%Next
        end do d1

    end subroutine ComputeBivalveCondition

    !--------------------------------------------------------------------------

    subroutine ComputeFeedingProcesses (Index, CheckIfOpenPoint)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)           :: Index
        integer, intent(IN)           :: CheckIfOpenPoint

        !Local-----------------------------------------------------------------
        type(T_Species),    pointer   :: Species
        type(T_Cohort),     pointer   :: Cohort

        !Begin-----------------------------------------------------------------

        !Choose feeding processes model
        if (CheckIfOpenPoint == OpenPoint) then

            if (Me%ComputeOptions%SimpleFiltration) then ! all are simple filtration model

                call ComputeSimpleFiltration (Index)

            else ! complex filtration model

                call ComputeComplexFiltration (Index) ! all will be computed as complex

            end if

        else

            Species => Me%Firstspecies
            d1:     do while(associated(Species))

                Cohort => Species%FirstCohort
                d2:     do while(associated(Cohort))

                    call ImposeNoFiltrationProcess (Cohort)

                    Cohort => Cohort%Next
                end do d2

                Species => Species%Next
            end do d1

        end if

    end subroutine ComputeFeedingProcesses

    !--------------------------------------------------------------------------

    subroutine ComputeSimpleFiltration (Index)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                 :: Index

        !Local-----------------------------------------------------------------
        type(T_Species),    pointer         :: Species
        type(T_Cohort),     pointer         :: Cohort
        integer                             :: M_H 
        integer                             :: POMcheck 
        real                                :: F_FIX, PAM_FIX, mu_E, YEX
        real                                :: C_AtomicMass, H_AtomicMass, O_AtomicMass
        real                                :: P_AtomicMass, N_AtomicMass
        real                                :: RATIOHC, RATIOOC, RATIONC, RATIOPC 
        real                                :: Vol, TempCorrection,MHb

        !Begin-----------------------------------------------------------------

        Species   => Me%FirstSpecies
        
d1:     do while(associated(Species))

            F_FIX           = Species%IndividualParameters%F_FIX 
            PAM_FIX         = Species%IndividualParameters%PAM_FIX 
            mu_E            = Species%IndividualParameters%mu_E
            YEX             = Species%IndividualParameters%YEX

            C_AtomicMass    = Species%AuxiliarParameters%C_AtomicMass        
            H_AtomicMass    = Species%AuxiliarParameters%H_AtomicMass        
            O_AtomicMass    = Species%AuxiliarParameters%O_AtomicMass        
            P_AtomicMass    = Species%AuxiliarParameters%P_AtomicMass        
            N_AtomicMass    = Species%AuxiliarParameters%N_AtomicMass        
            TempCorrection  = Species%AuxiliarParameters%TempCorrection         
            MHb             = Species%AuxiliarParameters%MHb  

            !Assumed the samecomposition as the bivalve 
            RATIOHC         = 0.15         
            RATIOOC         = 0.71         
            RATIONC         = 0.3 !0.3395653308501444         
            RATIOPC         = 0.07  

            Cohort => Species%FirstCohort
d2:         do while(associated(Cohort))

                M_H         = Cohort%StateIndex%M_H    
                Vol         = Cohort%BivalveCondition%Vol

                POMcheck = 0

                if (Me%ExternalVar%Mass(M_H,Index) .gt. MHb) then !feeding            

                    !Filtration, molC/d
                    Cohort%Processes%FilteredInorganic = 0.0
                    Cohort%Processes%FilteredFood%C    = F_FIX * PAM_FIX / mu_E * TempCorrection * Vol**(2.0/3.0) / YEX
                    Cohort%Processes%FilteredFood%H    = Cohort%Processes%FilteredFood%C * RATIOHC / H_AtomicMass * C_AtomicMass
                    Cohort%Processes%FilteredFood%O    = Cohort%Processes%FilteredFood%C * RATIOOC / O_AtomicMass * C_AtomicMass
                    Cohort%Processes%FilteredFood%N    = Cohort%Processes%FilteredFood%C * RATIONC / N_AtomicMass * C_AtomicMass
                    Cohort%Processes%FilteredFood%P    = Cohort%Processes%FilteredFood%C * RATIOPC / P_AtomicMass * C_AtomicMass

                    !Clearance rate, m3/d        
                    Cohort%Processes%ClearanceRate      = 0.0  

                    !Ingestion rate, molC/d        
                    Cohort%Processes%IngestionInorganic = 0.0  
                    Cohort%Processes%IngestionFood%C    = Cohort%Processes%FilteredFood%C
                    Cohort%Processes%IngestionFood%H    = Cohort%Processes%FilteredFood%H
                    Cohort%Processes%IngestionFood%O    = Cohort%Processes%FilteredFood%O
                    Cohort%Processes%IngestionFood%N    = Cohort%Processes%FilteredFood%N
                    Cohort%Processes%IngestionFood%P    = Cohort%Processes%FilteredFood%P

                    !Pseudo-faeces contribution rate, molC/d        
                    Cohort%Processes%PFContributionInorganic  = 0.0
                    Cohort%Processes%PFContributionFood%C     = 0.0
                    Cohort%Processes%PFContributionFood%H     = 0.0
                    Cohort%Processes%PFContributionFood%O     = 0.0
                    Cohort%Processes%PFContributionFood%N     = 0.0
                    Cohort%Processes%PFContributionFood%P     = 0.0

                    !Compute Assimilation, molC/d
                    Cohort%Processes%Assimilation%C    = F_FIX * PAM_FIX / mu_E * TempCorrection * Vol**(2.0/3.0)
                    Cohort%Processes%Assimilation%H    = Cohort%Processes%Assimilation%C * RATIOHC / H_AtomicMass * C_AtomicMass
                    Cohort%Processes%Assimilation%O    = Cohort%Processes%Assimilation%C * RATIOOC / O_AtomicMass * C_AtomicMass
                    Cohort%Processes%Assimilation%N    = Cohort%Processes%Assimilation%C * RATIONC / N_AtomicMass * C_AtomicMass
                    Cohort%Processes%Assimilation%P    = Cohort%Processes%Assimilation%C * RATIOPC / P_AtomicMass * C_AtomicMass

                    !Compute Faecesproduction, molC/d
                    Cohort%Processes%FaecesContributionInorganic = 0.0                                
                    Cohort%Processes%FaecesContributionFood%C    = Cohort%Processes%IngestionFood%C - &
                                                                   Cohort%Processes%Assimilation%C
                    Cohort%Processes%FaecesContributionFood%H    = Cohort%Processes%IngestionFood%H - &
                                                                   Cohort%Processes%Assimilation%H
                    Cohort%Processes%FaecesContributionFood%O    = Cohort%Processes%IngestionFood%O - &
                                                                   Cohort%Processes%Assimilation%O
                    Cohort%Processes%FaecesContributionFood%N    = Cohort%Processes%IngestionFood%N - &
                                                                   Cohort%Processes%Assimilation%N
                    Cohort%Processes%FaecesContributionFood%P    = Cohort%Processes%IngestionFood%P - &
                                                                   Cohort%Processes%Assimilation%P

                else ! if not (M_H .gt. MHb), dont feed

                    call ImposeNoFiltrationProcess (Cohort)

                end if !(M_H .gt. MHb) feeding

                Cohort%FeedingOn = 0.0

                Cohort => Cohort%Next

            end do d2

            Species => Species%Next

        end do d1

    end subroutine ComputeSimpleFiltration

    !--------------------------------------------------------------------------

    subroutine ImposeNoFiltrationProcess (Cohort)

        !Arguments-------------------------------------------------------------
        type(T_Cohort),       pointer :: Cohort

        !Local-----------------------------------------------------------------

        !Begin-----------------------------------------------------------------

        Cohort%Processes%ClearanceRate                 = 0.0
        Cohort%Processes%FilteredInorganic             = 0.0
        Cohort%Processes%FilteredFood%C                = 0.0
        Cohort%Processes%FilteredFood%H                = 0.0
        Cohort%Processes%FilteredFood%O                = 0.0
        Cohort%Processes%FilteredFood%N                = 0.0
        Cohort%Processes%FilteredFood%P                = 0.0

        Cohort%Processes%IngestionInorganic            = 0.0
        Cohort%Processes%IngestionFood%C               = 0.0
        Cohort%Processes%IngestionFood%H               = 0.0
        Cohort%Processes%IngestionFood%O               = 0.0
        Cohort%Processes%IngestionFood%N               = 0.0
        Cohort%Processes%IngestionFood%P               = 0.0

        Cohort%Processes%PFContributionInorganic       = 0.0
        Cohort%Processes%PFContributionFood%C          = 0.0
        Cohort%Processes%PFContributionFood%H          = 0.0
        Cohort%Processes%PFContributionFood%O          = 0.0
        Cohort%Processes%PFContributionFood%N          = 0.0
        Cohort%Processes%PFContributionFood%P          = 0.0
        Cohort%Processes%Assimilation%C                = 0.0
        Cohort%Processes%Assimilation%H                = 0.0
        Cohort%Processes%Assimilation%O                = 0.0
        Cohort%Processes%Assimilation%N                = 0.0
        Cohort%Processes%Assimilation%P                = 0.0

        Cohort%Processes%FaecesContributionInorganic   = 0.0
        Cohort%Processes%FaecesContributionFood%C      = 0.0
        Cohort%Processes%FaecesContributionFood%H      = 0.0
        Cohort%Processes%FaecesContributionFood%O      = 0.0
        Cohort%Processes%FaecesContributionFood%N      = 0.0
        Cohort%Processes%FaecesContributionFood%P      = 0.0

    end subroutine ImposeNoFiltrationProcess

    !--------------------------------------------------------------------------

    subroutine ComputeComplexFiltration(Index)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)           :: Index

        !Local-----------------------------------------------------------------
        type(T_Species),    pointer :: Species
        type(T_Cohort),     pointer :: Cohort
        type(T_Particles),  pointer :: Particles
        integer                     :: PON, POP, POC, BioSilica, diatoms, DiatomsSi 
        integer                     :: M_H, Number
        integer                     :: POMcheck = 0, par
        real                        :: Crm, JX1Fm, JX0Fm, ro_X1, ro_X0, JX1Im, JX0Im, mu_E, YEX
        real                        :: C_AtomicMass, H_AtomicMass, O_AtomicMass, N_AtomicMass, P_AtomicMass
        real                        :: TempCorrection, Vol, MHb
        real                        :: CrDenominator, IngDenominator !, ComputedYEX
        real                        :: Total_CR, Total_ParticlePotFil, Total_PossibleParticleFil
        real                        :: ParticleConcentration, ParticleTempMass
        real                        :: FilteredByCohort,IngestedByCohort, AssimilatedByCohort
        real                        :: FilteredBySpecies,IngestedBySpecies, AssimilatedBySpecies
        real                        :: PseudoFaecesBySpecies,FaecesBySpecies
        integer                     :: ParticlesIndex 
        real                        :: r_C, r_N, r_P
        integer                     :: PropertyIndexC,PropertyIndexN, PropertyIndexP, PropertyIndexChl  
        real                        :: AssimilatedStructure, AssimilatedReserves
        
        real                        :: aqui

        !Begin-----------------------------------------------------------------

        POC           = Me%PropIndex%POC
        PON           = Me%PropIndex%PON
        POP           = Me%PropIndex%POP
        BioSilica     = Me%PropIndex%BioSilica
        diatoms       = Me%PropIndex%diatoms
        DiatomsSi     = Me%PropIndex%DiatomsSi

        POMcheck      = 0
        Me%LackOfFood = 0.0            

        !1st: Clearance Rate for each cohorts of each species, m3/d/individual

        Total_CR      = 0.0 !total for all individuals in the system

        Species => Me%FirstSpecies
d1:     do while(associated(Species))

            Crm            = Species%IndividualParameters%Crm 
            JX1Fm          = Species%IndividualParameters%JX1Fm      
            JX0Fm          = Species%IndividualParameters%JX0Fm      
            ro_X1          = Species%IndividualParameters%ro_X1      
            ro_X0          = Species%IndividualParameters%ro_X0      
            JX1Im          = Species%IndividualParameters%JX1Im      
            JX0Im          = Species%IndividualParameters%JX0Im
            YEX            = Species%IndividualParameters%YEX    
            mu_E           = Species%IndividualParameters%mu_E

            TempCorrection = Species%AuxiliarParameters%TempCorrection         
            C_AtomicMass   = Species%AuxiliarParameters%C_AtomicMass        
            H_AtomicMass   = Species%AuxiliarParameters%H_AtomicMass        
            O_AtomicMass   = Species%AuxiliarParameters%O_AtomicMass        
            P_AtomicMass   = Species%AuxiliarParameters%P_AtomicMass        
            N_AtomicMass   = Species%AuxiliarParameters%N_AtomicMass        
            MHb            = Species%AuxiliarParameters%MHb  

            !Compute CRdenominator = 1 + sum(Xi*CRM/JXim), Xi in molC/m3
            !base on all the properties that are food for this species, it does not depend on the cohorts
            CrDenominator = 1.0

            Particles => Species%FirstParticles
d3:         do while(associated(Particles))

                if (Particles%Organic .eq. 1) then

                    if (Particles%ID%Name .eq.'particulate organic matter') then

                        if (Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then

                            if  (Me%ComputeOptions%Nitrogen) then

                                !Amount of POC based on the PON value, using the NCratio and converted to molC
                                CrDenominator = CrDenominator                                                 + &
                                                (Me%ExternalVar%Mass(PON,Index) / Particles%Ratios%NC_Ratio)  / &
                                                C_AtomicMass * Crm / JX1Fm

                            else

                                !Only if the model is running just with P
                                !Amount of POC based on the POP value, using the PCratio and converted to molC
                                CrDenominator = CrDenominator                                                 + &
                                (Me%ExternalVar%Mass(POP,Index) / Particles%Ratios%PC_Ratio)                  / &
                                C_AtomicMass * Crm / JX1Fm

                            end if

                        else
                        ! if Life

                            !For filtration
                            !Amount of POC 
                            CrDenominator = CrDenominator + Me%ExternalVar%Mass(POC,Index)/C_AtomicMass * Crm / JX1Fm  

                        end if ! Me%ComputeOptions%PelagicModel

                    else
                    !if not 'particulate organic matter' 

                        if (Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then

                            ParticlesIndex = SearchPropIndex(GetPropertyIDNumber(Particles%ID%Name))

                        else
                        !if Life

                            ParticlesIndex = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" carbon")))

                        end if

                        !For clearance rate
                        CrDenominator = CrDenominator + Me%ExternalVar%Mass(ParticlesIndex,Index)/C_AtomicMass * Crm / JX1Fm

                    end if !'particulate organic matter'   

                else !if not organic

                    ParticlesIndex = SearchPropIndex(GetPropertyIDNumber(Particles%ID%Name))

                    !For filtration
                    CrDenominator = CrDenominator + Me%ExternalVar%Mass(ParticlesIndex,Index) * Crm / JX0Fm

                end if !(Particles%Organic .eq. 1)

                Particles => Particles%Next

            end do d3

            !Clearance rate, m3/d/individual in each cohort
            Cohort => Species%FirstCohort
d2:         do while(associated(Cohort))

                M_H    = Cohort%StateIndex%M_H    
                Number = Cohort%StateIndex%Number    
                Vol    = Cohort%BivalveCondition%Vol        

                if (Me%ExternalVar%Mass(M_H,Index) .gt. MHb) then !feeding            

                    Cohort%Processes%ClearanceRate = Crm * Tempcorrection * Vol**(2.0/3.0) / CrDenominator 

                    !Total Clearance rate, m3/d (.m3), sum all individuals in the system
                    !m3/d (.m3) = m3/d.ind * ind/m3
                    Total_CR = Total_CR + Cohort%Processes%ClearanceRate * Me%ExternalVar%Mass(Number,Index)

                else ! if not (M_H .gt. MHb)

                    Cohort%Processes%ClearanceRate = 0.0

                end if !(M_H .gt. MHb) feeding

                !Initialize to proceed with computation       
                Cohort%Processes%FilteredInorganic           = 0.0
                Cohort%Processes%FilteredFood%C              = 0.0
                Cohort%Processes%FilteredFood%H              = 0.0
                Cohort%Processes%FilteredFood%O              = 0.0
                Cohort%Processes%FilteredFood%N              = 0.0
                Cohort%Processes%FilteredFood%P              = 0.0

                Cohort%Processes%IngestionInorganic          = 0.0
                Cohort%Processes%IngestionFood%C             = 0.0
                Cohort%Processes%IngestionFood%H             = 0.0
                Cohort%Processes%IngestionFood%O             = 0.0
                Cohort%Processes%IngestionFood%N             = 0.0
                Cohort%Processes%IngestionFood%P             = 0.0

                Cohort%Processes%PFContributionInorganic     = 0.0
                Cohort%Processes%PFContributionFood%C        = 0.0
                Cohort%Processes%PFContributionFood%H        = 0.0
                Cohort%Processes%PFContributionFood%O        = 0.0
                Cohort%Processes%PFContributionFood%N        = 0.0
                Cohort%Processes%PFContributionFood%P        = 0.0

                Cohort%Processes%Assimilation%C              = 0.0
                Cohort%Processes%Assimilation%H              = 0.0
                Cohort%Processes%Assimilation%O              = 0.0
                Cohort%Processes%Assimilation%N              = 0.0
                Cohort%Processes%Assimilation%P              = 0.0

                Cohort%Processes%FaecesContributionInorganic = 0.0
                Cohort%Processes%FaecesContributionFood%C    = 0.0
                Cohort%Processes%FaecesContributionFood%H    = 0.0
                Cohort%Processes%FaecesContributionFood%O    = 0.0
                Cohort%Processes%FaecesContributionFood%N    = 0.0
                Cohort%Processes%FaecesContributionFood%P    = 0.0

                Cohort => Cohort%Next

            end do d2

            Species => Species%Next

        end do d1

        !2st: Filtration Rate for each cohorts of each species, m3/d/individual
        Species => Me%FirstSpecies
d4:     do while(associated(Species))

            par = 0

            !search for particle concentration, in molC/d if organic, g/d if inorganic
            Particles => Species%FirstParticles
d5:         do while(associated(Particles))

                par = par + 1 !count which property

                ParticleConcentration = 0.0
               
                if (Particles%Organic .eq. 1) then

                    if (Particles%ID%Name .eq.'particulate organic matter') then

                        POMcheck = 1

                        if (Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then

                            if (Me%ComputeOptions%Nitrogen) then

                                !amount of carbon associated with PON property, em molC/m3
                                !mgN/l / mgN/mgC / g/mol = mol/m3 . 
                                ParticleConcentration = (Me%ExternalVar%Mass(PON,Index)             / &
                                                         Particles%Ratios%NC_Ratio)                 / &
                                                         C_AtomicMass
                            else 
                                !Only if the model is running just with P
                                !carbon associated with POP property, mol/d            
                                ParticleConcentration = (Me%ExternalVar%Mass(POP,Index)             / &
                                                         Particles%Ratios%PC_Ratio)                 / &
                                                         C_AtomicMass
                            end if

                        else
                        !Life

                            !amount of carbon associated with PON property, em mol/d
                            ParticleConcentration = Me%ExternalVar%Mass(POC,Index) / C_AtomicMass             
                        
                        end if 

                    else         
                    !if not 'particulate organic matter'            

                        if (Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then
                            ParticlesIndex = SearchPropIndex(GetPropertyIDNumber(Particles%ID%Name))
                        else
                            !if Life
                            ParticlesIndex = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" carbon")))
                        end if

                        !molC/m3 = g/m3 * molC/g 
                        ParticleConcentration = Me%ExternalVar%Mass(ParticlesIndex,Index) / C_AtomicMass 
                        
                    end if  !if 'particulate organic matter'     

                else !not organic

                    ParticlesIndex = SearchPropIndex(GetPropertyIDNumber(Particles%ID%Name))

                    !g/m3
                    ParticleConcentration = Me%ExternalVar%Mass(ParticlesIndex,Index)

                end if !organic

                !Potential Total filtration of this particle molC(g)/d(.m3) = m3/d(.m3) * molC/m3
                Total_ParticlePotFil = Total_CR * ParticleConcentration

                !check if it is possible, in mass
                !molC.m3 = molC/m3 - molC/d(.m3) * d
                ParticleTempMass = ParticleConcentration - Total_ParticlePotFil * Me%DTDay 

                if (ParticleTempMass .lt. 0.0) then

                    Me%LackOfFood = 1.0

                    !molC/d (.m3) = molC/m3 / d
                    Total_PossibleParticleFil = ParticleConcentration / Me%DTDay

                else

                    !molC/d (.m3)
                    Total_PossibleParticleFil = Total_ParticlePotFil

                endif

                Cohort => Species%FirstCohort
d6:             do while(associated(Cohort))

                    if (Total_CR .ne. 0.0) then

                        Number = Cohort%StateIndex%Number    

                        if (Me%ComputeOptions%CorrectFiltration) then
                        
                            if (Me%ExternalVar%Mass(Number,Index) .ne. 0.0) then
                            
                                !molC/d.ind
                                FilteredByCohort = Cohort%Processes%ClearanceRate                      * &
                                                   Me%ExternalVar%Mass(Number,Index) / Total_CR        * &
                                                   Total_PossibleParticleFil                           / &
                                                   Me%ExternalVar%Mass(Number,Index)
                            
                            else
                            
                                FilteredByCohort = 0.0
                                
                            end if
                            

                        else
                        !molC/d.ind
                            FilteredByCohort = Cohort%Processes%ClearanceRate * ParticleConcentration 

                        end if
                        
                    else
                    
                        FilteredByCohort = 0.0
                    
                    end if

                    !store value in the Filtered column, in molC or molC/d.ind
                    Cohort%FeedingOn(par,1) = FilteredByCohort

                    if (Particles%Organic .eq. 1) then

                        !Total filtration from organic material, molC/d
                        Cohort%Processes%FilteredFood%C = Cohort%Processes%FilteredFood%C + FilteredByCohort

                        Cohort%Processes%FilteredFood%H = Cohort%Processes%FilteredFood%H +                  &
                                                          FilteredByCohort * Particles%Composition%nH
                                                          
                        Cohort%Processes%FilteredFood%O = Cohort%Processes%FilteredFood%O +                  &
                                                          FilteredByCohort * Particles%Composition%nO
                                                          
                        Cohort%Processes%FilteredFood%N = Cohort%Processes%FilteredFood%N +                  &
                                                          FilteredByCohort * Particles%Composition%nN
                                                          
                        Cohort%Processes%FilteredFood%P = Cohort%Processes%FilteredFood%P +                  &
                                                          FilteredByCohort * Particles%Composition%nP

                    else !inorganic

                        !Total filtration from inorganic material, g/d
                        Cohort%Processes%FilteredInorganic = Cohort%Processes%FilteredInorganic + FilteredByCohort

                    end if

                    Cohort => Cohort%Next
                end do d6
                Particles => Particles%Next
            end do d5 !to have the total carbon Filtered by each cohort from all properties

            !3st: Compute ingestion and assimilation, molC/d/individual
            Cohort => Species%FirstCohort
    d7:     do while(associated(Cohort))

                !Because ro_Xi and JXiIm are the same for all organic particles
                IngDenominator = 1 + (ro_X1 * Cohort%Processes%FilteredFood%C) / JX1Im + &
                (ro_X0 * Cohort%Processes%FilteredInorganic) / JX0Im

                par = 0

                Particles => Species%FirstParticles
    d8:         do while(associated(Particles)) !round to compute IngestedByCohort (second column of FeedingOn matrix9

                    par = par + 1

                    FilteredByCohort = Cohort%FeedingOn(par,1)

                    if (Particles%Organic .eq. 1) then

                        !Ingestion from each food item, molC/d(.m3) 
                        IngestedByCohort = ro_X1 * FilteredByCohort / IngDenominator 

                        !Ingestion: sum of all ingested carbon form the different food itens, mol/d
                        Cohort%Processes%IngestionFood%C = Cohort%Processes%IngestionFood%C + IngestedByCohort

                        Cohort%Processes%IngestionFood%H = Cohort%Processes%IngestionFood%H                 + &
                                                            IngestedByCohort * Particles%Composition%nH

                        Cohort%Processes%IngestionFood%O = Cohort%Processes%IngestionFood%O                 + &
                                                            IngestedByCohort * Particles%Composition%nO

                        Cohort%Processes%IngestionFood%N = Cohort%Processes%IngestionFood%N                 + &
                                                            IngestedByCohort * Particles%Composition%nN

                        Cohort%Processes%IngestionFood%P = Cohort%Processes%IngestionFood%P                 + &
                                                            IngestedByCohort * Particles%Composition%nP

                        !Pseudofaeces: sum of all contributions form all the different food itens, mol/d(.ind)
                        Cohort%Processes%PFContributionFood%C = Cohort%Processes%PFContributionFood%C       + &
                                                            (FilteredByCohort - IngestedByCohort)

                        Cohort%Processes%PFContributionFood%H = Cohort%Processes%PFContributionFood%H       + &
                                                            (FilteredByCohort - IngestedByCohort) * Particles%Composition%nH

                        Cohort%Processes%PFContributionFood%O = Cohort%Processes%PFContributionFood%O       + &
                                                            (FilteredByCohort - IngestedByCohort) * Particles%Composition%nO

                        Cohort%Processes%PFContributionFood%N = Cohort%Processes%PFContributionFood%N       + &
                                                            (FilteredByCohort - IngestedByCohort) * Particles%Composition%nN 

                        Cohort%Processes%PFContributionFood%P = Cohort%Processes%PFContributionFood%P       + &
                                                            (FilteredByCohort - IngestedByCohort) * Particles%Composition%nP

                        if (Species%IndividualParameters%SIMPLE_ASSI .eq. 1) then !simple assimilation model

                            !Assimilation, molC/d
                            AssimilatedByCohort = IngestedByCohort * YEX

                        else !not SIMPLE_ASSI

                            if (IngestedByCohort .gt. 1e-20) then

                                if ((Particles%ID%Name .eq. 'particulate organic matter')) then 

                                    Particles%F_E = 1

                                end if 

                                !Assimilation: Structure, simple relation using the yield coefficient
                                AssimilatedStructure = IngestedByCohort * (1-Particles%F_E) * YEX

                                !Assimilation: Reserves, Parallel and complementary SU's for three elements, molC/d
                                r_C = IngestedByCohort * Particles%F_E

                                r_N = IngestedByCohort * Particles%F_E                              * &
                                        Particles%Composition%nN                                    / &
                                        Species%SpeciesComposition%ReservesComposition%nN

                                r_P = IngestedByCohort * Particles%F_E                              * &
                                        Particles%Composition%nP                                    / &
                                        Species%SpeciesComposition%ReservesComposition%nP

                                AssimilatedReserves = ( 1/r_C                       + &
                                                        1/r_N                       + &
                                                        1/r_P                       - &
                                                        1/(r_C + r_N)               - &
                                                        1/(r_C + r_P)               - &
                                                        1/(r_N + r_P)               + &
                                                        1/(r_C + r_N + r_P))          &
                                                        **(-1)

                                !Assimilation: Reserves + Structure, molC/d       
                                AssimilatedByCohort = AssimilatedStructure + AssimilatedReserves       

                            else
                            !Assimilation: Reserves + Structure, molC/d(.m3)       
                            AssimilatedByCohort = 0.0       

                            end if !if ingestion !=0.0

                        end if !if SIMPLE_ASSI

                        !Total Assimilation in C, mol/d
                        Cohort%Processes%Assimilation%C = Cohort%Processes%Assimilation%C + AssimilatedByCohort

                        !Total Faeces Contribution in C, mol/d
                        Cohort%Processes%FaecesContributionFood%C = Cohort%Processes%FaecesContributionFood%C + &
                        (IngestedByCohort - AssimilatedByCohort) 
                    else !not organic

                        !Ingestion, g/d
                        IngestedByCohort = ro_X0 * FilteredByCohort / IngDenominator  

                        !Ingestion: sum of all ingested mass of inorganic material that the mussel is able to ingest, g/d
                        Cohort%Processes%IngestionInorganic = Cohort%Processes%IngestionInorganic + IngestedByCohort

                        !Pseudofaeces: sum of all pseudofaeces from inorganic material, g/d
                        Cohort%Processes%PFContributionInorganic = Cohort%Processes%PFContributionInorganic  + &
                        (FilteredByCohort - IngestedByCohort)

                        !Assimilation: inorganic material can not be assimilated
                        AssimilatedByCohort = 0.0

                        !Faeces: sum of all faeces from inorganic material, g/d
                        Cohort%Processes%FaecesContributionInorganic = Cohort%Processes%FaecesContributionInorganic +   &
                        (IngestedBySpecies - AssimilatedBySpecies)

                    end if !organic

                    !store value in the ingested column
                    Cohort%FeedingOn(par,2) = IngestedByCohort

                    !store value in the assimilated column
                    Cohort%FeedingOn(par,3) = AssimilatedByCohort

                    Particles => Particles%Next

                end do d8    

                !ComputedYEX = Cohort%Processes%Assimilation%C / Cohort%Processes%IngestionFood%C 

                !Total Assimilation for the other elements, mol/d(.m3)
                Cohort%Processes%Assimilation%H = Cohort%Processes%Assimilation%C                  * &
                                                  Species%SpeciesComposition%ReservesComposition%nH

                Cohort%Processes%Assimilation%O = Cohort%Processes%Assimilation%C                  * &
                                                  Species%SpeciesComposition%ReservesComposition%nO

                Cohort%Processes%Assimilation%N = Cohort%Processes%Assimilation%C                  * &
                                                  Species%SpeciesComposition%ReservesComposition%nN

                Cohort%Processes%Assimilation%P = Cohort%Processes%Assimilation%C                  * &
                                                  Species%SpeciesComposition%ReservesComposition%nP

                !Total Faeces production for the other elements, mol/d
                Cohort%Processes%FaecesContributionFood%H = Cohort%Processes%IngestionFood%H - Cohort%Processes%Assimilation%H
                Cohort%Processes%FaecesContributionFood%O = Cohort%Processes%IngestionFood%O - Cohort%Processes%Assimilation%O
                Cohort%Processes%FaecesContributionFood%N = Cohort%Processes%IngestionFood%N - Cohort%Processes%Assimilation%N
                Cohort%Processes%FaecesContributionFood%P = Cohort%Processes%IngestionFood%P - Cohort%Processes%Assimilation%P

                Cohort => Cohort%Next
            end do d7
            Species => Species%Next

        end do d4 !to have the total carbon Filtered by each cohort from all properties

        !Matrix Mass update
        Species => Me%FirstSpecies
d9:     do while(associated(Species))

            par = 0

            Particles => Species%FirstParticles
d10:        do while(associated(Particles))

                par = par + 1

                FilteredBySpecies    = 0.0
                IngestedBySpecies    = 0.0
                AssimilatedBySpecies = 0.0

                Cohort => Species%FirstCohort
d11:            do while(associated(Cohort))

                    Number = Cohort%StateIndex%Number

                    !Sum all filtration of this property by all the cohorts in this species, molC/d
                    FilteredBySpecies     = Cohort%FeedingOn(par,1)

                    !Sum all ingestion of this property by all the cohorts in this species, molC/d
                    IngestedBySpecies     = Cohort%FeedingOn(par,2)

                    !Sum all assimilation of this property by all the cohorts in this species, molC/d
                    AssimilatedBySpecies  = Cohort%FeedingOn(par,3)

                    !Pseudofaeces and Faeces form this species on this particles
                    PseudoFaecesBySpecies = FilteredBySpecies - IngestedBySpecies

                    FaecesBySpecies = IngestedBySpecies - AssimilatedBySpecies

                    if (Particles%Organic .eq. 0) then !inorganic particle

                        ParticlesIndex = SearchPropIndex(GetPropertyIDNumber(Particles%ID%Name))

                        Me%ExternalVar%Mass (ParticlesIndex, Index) = Me%ExternalVar%Mass (ParticlesIndex, Index)   + &
                                                                     ( PseudoFaecesBySpecies                        + &
                                                                       FaecesBySpecies                              - &
                                                                       FilteredBySpecies)                           * &
                                                                       Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                    else
                    !if organic         

                        if (Particles%ID%Name .eq.'particulate organic matter') then

                            if(Me%ComputeOptions%Nitrogen)then

                                Me%ExternalVar%Mass (PON, Index) = Me%ExternalVar%Mass (PON, Index)                + &
                                                            ( Cohort%Processes%FaecesContributionFood%N            + &
                                                              Cohort%Processes%PFContributionFood%N                - &
                                                              FilteredBySpecies * Particles%Composition%nN )       * &
                                                              N_AtomicMass                                         * &
                                                              Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                            end if   

                            if(Me%ComputeOptions%Phosphorus) then       

                                Me%ExternalVar%Mass (POP, Index) = Me%ExternalVar%Mass (POP, Index)                + &
                                                            ( Cohort%Processes%FaecesContributionFood%P            + &
                                                              Cohort%Processes%PFContributionFood%P                - & 
                                                              FilteredBySpecies * Particles%Composition%nP )       * &
                                                              P_AtomicMass                                         * &
                                                              Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                            end if   

                            if(Me%ComputeOptions%PelagicModel .eq. LifeModel) then    

                                Me%ExternalVar%Mass (POC, Index) = Me%ExternalVar%Mass (POC, Index)                + &
                                                            ( Cohort%Processes%FaecesContributionFood%C            + &
                                                              Cohort%Processes%PFContributionFood%C                - & 
                                                              FilteredBySpecies)                                   * &
                                                              C_AtomicMass                                         * &
                                                              Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                            end if

                        else
                        !if not 'particulate organic matter'

                            if(Me%ComputeOptions%PelagicModel .eq. WaterQualityModel ) then

                                if (Particles%ID%Name .eq.'diatoms') then

                                    if(Particles%Silica .eq. 1)then
                                    
                                        !All the silica ingested is returned to the water in the form of biosilica
                                        Me%ExternalVar%Mass (BioSilica, Index) = Me%ExternalVar%Mass(BioSilica, Index)+ &
                                                                        FilteredBySpecies                             * &
                                                                        C_AtomicMass * Particles%Ratios%SiC_Ratio     * &
                                                                        Me%ExternalVar%Mass(Number, Index) * Me%DTDay
                                        
                                    end if

                                end if                          
                            
                            ParticlesIndex = SearchPropIndex(GetPropertyIDNumber(Particles%ID%Name))
                            
                            aqui = Me%ExternalVar%Mass (ParticlesIndex, Index)

                            Me%ExternalVar%Mass (ParticlesIndex, Index) = Me%ExternalVar%Mass (ParticlesIndex, Index) - &
                                                                        FilteredBySpecies  * Me%DTDay                 * &
                                                                        Me%ExternalVar%Mass(Number, Index)            * &
                                                                        C_AtomicMass !volume

                            !temporario
                            if (Me%ExternalVar%Mass (ParticlesIndex, Index) .lt. 0.0) then
                            
                                Me%MassLoss = Me%MassLoss + Me%ExternalVar%Mass (ParticlesIndex, Index) * (-1.)
                                
                                Me%ExternalVar%Mass (ParticlesIndex, Index) = 0.0
                            end if

                        else     
                        !if life 

                            if (Particles%ID%Name .eq.'diatoms') then             

                                Me%ExternalVar%Mass (DiatomsSi, Index) = Me%ExternalVar%Mass (DiatomsSi, Index) -        &
                                FilteredBySpecies * C_AtomicMass *    &
                                Particles%Ratios%SiC_Ratio *          &
                                Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                                Me%ExternalVar%Mass (BioSilica, Index) = Me%ExternalVar%Mass (BioSilica, Index) +        &
                                FilteredBySpecies *     &
                                C_AtomicMass * Particles%Ratios%SiC_Ratio *         &
                                Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                            end if

                            PropertyIndexC = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" carbon")))
                            PropertyIndexN = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" nitrogen")))
                            PropertyIndexP = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//" phosphorus")))

                            Me%ExternalVar%Mass (PropertyIndexC, Index) = Me%ExternalVar%Mass (PropertyIndexC, Index) - &
                                                                        FilteredBySpecies * C_AtomicMass              * &
                                                                        Me%ExternalVar%Mass(Number, Index) * Me%DTDay 

                            Me%ExternalVar%Mass (PropertyIndexN, Index) = Me%ExternalVar%Mass (PropertyIndexN, Index) - &
                                                                        FilteredBySpecies * Particles%Composition%nN  * &
                                                                        N_AtomicMass                                  * &
                                                                        Me%ExternalVar%Mass(Number, Index) * Me%DTDay 

                            Me%ExternalVar%Mass (PropertyIndexP, Index) = Me%ExternalVar%Mass (PropertyIndexP, Index) - &
                                                                        FilteredBySpecies * Particles%Composition%nP  * &      &
                                                                        P_AtomicMass                                  * &
                                                                        Me%ExternalVar%Mass(Number, Index) * Me%DTDay 


                            if ((Particles%ID%Name .eq. 'diatoms') .or. (Particles%ID%Name .eq. 'autotrophic flagellates') .or.&
                            (Particles%ID%Name .eq. 'picoalgae') .or. (Particles%ID%Name .eq. 'flagellates')) then 

                                PropertyIndexChl = SearchPropIndex(GetPropertyIDNumber((trim(Particles%ID%Name)//   &
                                                    " chlorophyll")))

                                Me%ExternalVar%Mass (PropertyIndexChl, Index) = Me%ExternalVar%Mass (PropertyIndexChl, Index)- &
                                                                            FilteredBySpecies *  C_AtomicMass *     &
                                                                            Particles%Ratios%ChlC_Ratio *           &
                                                                            Me%ExternalVar%Mass(Number, Index) * Me%DTDay  

                            end if

                        !if life
                        end if

                    end if !if Organic matter

                    ! if is organic    
                    end if 

                    !update PON, POC and POC when it is not a property from the properties list (does not have filtration)
                    if (POMcheck .eq. 0) then

                        if(Me%ComputeOptions%Nitrogen)then
                        !g
                            Me%ExternalVar%Mass (PON, Index) = Me%ExternalVar%Mass (PON, Index)             + &
                                                            (Cohort%Processes%PFContributionFood%N          + &
                                                             Cohort%Processes%FaecesContributionFood%N)     * &
                                                             N_AtomicMass                                   * &
                                                             Me%ExternalVar%Mass(Number, Index) * Me%DTDay
                       
                        end if   

                        if(Me%ComputeOptions%Phosphorus) then       

                            Me%ExternalVar%Mass (POP, Index) = Me%ExternalVar%Mass (POP, Index)             + &
                                                            (Cohort%Processes%PFContributionFood%P          + &
                                                             Cohort%Processes%FaecesContributionFood%P)     * &
                                                             P_AtomicMass                                   * &
                                                             Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                        end if   

                        if(Me%ComputeOptions%PelagicModel .eq. LifeModel) then    

                            Me%ExternalVar%Mass (POC, Index) = Me%ExternalVar%Mass (POC, Index)             + &
                                                            (Cohort%Processes%PFContributionFood%C          + &
                                                             Cohort%Processes%FaecesContributionFood%C)     * &
                                                             C_AtomicMass                                   * &
                                                             Me%ExternalVar%Mass(Number, Index) * Me%DTDay

                        end if

                    end if !PON, POP and POC are not in the list of properties        

                    Cohort => Cohort%Next
                end do d11

                Particles => Particles%Next
            end do d10

        Species => Species%Next
        end do d9

    end subroutine ComputeComplexFiltration

    !--------------------------------------------------------------------------

    subroutine ComputeSomaticMaintenance(Species, Cohort)

    !Arguments-------------------------------------------------------------
    type(T_Species),      pointer :: Species
    type(T_Cohort),       pointer :: Cohort

    !Local-----------------------------------------------------------------
    real            :: pM, mu_E
    real            :: TempCorrection, Vol  
    !Begin-----------------------------------------------------------------


    pM = Species%IndividualParameters%pM   
    mu_E             = Species%IndividualParameters%mu_E

    TempCorrection   = Species%AuxiliarParameters%TempCorrection         
    Vol= Cohort%BivalveCondition%Vol

    !J_ES, molC (reserves)/d, Somatic maintenance, Fraccion proporcional to the body volume     
    Cohort%Processes%SomaticMaintenance = pM / mu_E * Tempcorrection * Vol

    end subroutine ComputeSomaticMaintenance

    !--------------------------------------------------------------------------

    subroutine ComputeMobilization(Species, Cohort)

    !Arguments-------------------------------------------------------------
    type(T_Species),      pointer :: Species
    type(T_Cohort),       pointer :: Cohort


    !Local-----------------------------------------------------------------
    real            :: Vol,TempCorrection,E
    real            :: pM, mu_E, EG,v_cond,kappa  
    !Begin-----------------------------------------------------------------

    Vol   = Cohort%BivalveCondition%Vol
    E     = Cohort%BivalveCondition%E 

    TempCorrection      = Species%AuxiliarParameters%TempCorrection         

    pM    = Species%IndividualParameters%pM   
    mu_E  = Species%IndividualParameters%mu_E
    EG    = Species%IndividualParameters%EG     
    v_cond= Species%IndividualParameters%v_cond 
    kappa = Species%IndividualParameters%kappa

    if (Vol .eq. 0) then

    Cohort%Processes%Mobilization = 0.0

    else

    !molC (res)/d, Mobilization
    Cohort%Processes%Mobilization = E / (EG/mu_E + kappa * E)       *  &
    (EG/mu_E * v_cond * TempCorrection * Vol**(2./3.) + Cohort%Processes%SomaticMaintenance)

    end if

    end subroutine ComputeMobilization

    !--------------------------------------------------------------------------

    subroutine ComputeReservesDynamics(Index, Cohort)

    !Arguments-------------------------------------------------------------
    integer, intent(IN)           :: Index
    type(T_Cohort),       pointer :: Cohort


    !Local-----------------------------------------------------------------
    integer         :: M_E

    !Begin-----------------------------------------------------------------

    M_E = Cohort%StateIndex%M_E

    !molC (res)/d, Reserves dynamics, J_E
    Cohort%Processes%ReservesDynamics = (Cohort%Processes%Assimilation%C -         &  
    Cohort%Processes%Mobilization)

    !Matrix Mass update
    Me%ExternalVar%Mass(M_E, Index) = Me%ExternalVar%Mass(M_E, Index) +            &
    Cohort%Processes%ReservesDynamics * Me%DTDay

    end subroutine ComputeReservesDynamics

    !--------------------------------------------------------------------------

    subroutine ComputeStructureDynamics(Index, Species, Cohort)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                                 :: Index
        type(T_Species)            , pointer                :: Species
        type(T_Cohort)             , pointer                :: Cohort


        !Local-----------------------------------------------------------------
        integer                                             :: M_V, M_R
        real                                                :: kappa, y_VE

        !Begin-----------------------------------------------------------------

        M_V     = Cohort%StateIndex%M_V
        M_R     = Cohort%StateIndex%M_R

        kappa   = Species%IndividualParameters%kappa

        y_VE    = Species%AuxiliarParameters%y_VE 

        !Compute allocation fraction to growth and somatic maintenance(kJC), molC(reserves)/d
        Cohort%Processes%ToGrowthAndSomatic = kappa * Cohort%Processes%Mobilization

        !Compute flux to growth (JVG), molC(structure)/d
        Cohort%Processes%ToGrowth = (Cohort%Processes%ToGrowthAndSomatic - Cohort%Processes%SomaticMaintenance) * y_VE

        if (Cohort%Processes%ToGrowth .gt. 0) then

            Cohort%Processes%GametesLoss       = 0.0
            Cohort%Processes%StructureLoss     = 0.0

        else
        !(ToGrowth < 0)

            !molC(res)/d
            Cohort%Processes%SomaticMaintenanceNeeds =  - Cohort%Processes%ToGrowth

            Cohort%Processes%ToGrowth  = 0.0

            if (Me%ExternalVar%Mass(M_R, Index) .gt. 0) then

                if (Me%ExternalVar%Mass(M_R, Index) .gt. (Cohort%Processes%SomaticMaintenanceNeeds * Me%DTDay)) then

                    !from gamets
                    Cohort%Processes%GametesLoss   = Cohort%Processes%SomaticMaintenanceNeeds
                    Cohort%Processes%StructureLoss = 0.0

                else
                    !from gamets, molC(res)/d
                    Cohort%Processes%GametesLoss   = Me%ExternalVar%Mass(M_R, Index) / Me%DTDay

                    !and from structure, molC(res)/d 
                    Cohort%Processes%StructureLoss = (Cohort%Processes%SomaticMaintenanceNeeds - Cohort%Processes%GametesLoss) &
                    / y_VE

                end if

            else
            !(MRReproduction = 0)

                Cohort%Processes%GametesLoss   = 0.0

                !and from structure
                Cohort%Processes%StructureLoss = Cohort%Processes%SomaticMaintenanceNeeds / y_VE

            end if

        end if

        !Structure Dynamics, molC(struc)/d
        Cohort%Processes%StructureDynamics = Cohort%Processes%ToGrowth - Cohort%Processes%StructureLoss   

        !Matrix Mass update
        Me%ExternalVar%Mass(M_V,Index) = Me%ExternalVar%Mass(M_V,Index) +             &
        Cohort%Processes%StructureDynamics * Me%DTDay

        if (Me%ExternalVar%Mass(M_V,Index) .lt. Species%IndividualParameters%MVb) then

            Cohort%Processes%DeathByStarvation = Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) /  &
            Me%DTDay !All die from starvation

            if ((Cohort%Dead .eq. 0 )) then 
            
                call ImposeCohortDeath (Index, Species, Cohort) !sets all proc to zero, convert mass to OM, Deadlist

                if ((Species%nCohorts .eq. 1) .and. ((Cohort%Dead .eq. 1 ))) then !this was the last cohort of the population...                        

                    Species%PopulationProcesses%LastCauseofDeath(3) = Cohort%Processes%DeathByStarvation
                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                    
                end if
                
                !set the state of the dead cohort to zero
                Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)      = 0.0
                Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) = 0.0

            end if

        end if    

    end subroutine ComputeStructureDynamics

    !--------------------------------------------------------------------------

    subroutine ComputeMaturity(Index, Species, Cohort)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                         :: Index
        type(T_Species)         , pointer           :: Species
        type(T_Cohort)          , pointer           :: Cohort


        !Local-----------------------------------------------------------------
        integer                                     :: L, M_V, M_H, M_R
        real                                        :: kappa 
        real                                        :: kJ, Vol, MHp, MHb, Lb, TempCorrection

        !Begin-----------------------------------------------------------------

        L       = Cohort%StateIndex%L
        M_V     = Cohort%StateIndex%M_V
        M_H     = Cohort%StateIndex%M_H
        M_R     = Cohort%StateIndex%M_R

        kappa   = Species%IndividualParameters%kappa  
        Lb      = Species%IndividualParameters%Lb  

        MHp     = Species%AuxiliarParameters%MHp  
        MHb     = Species%AuxiliarParameters%MHb  
        kJ      = Species%AuxiliarParameters%kJ
        TempCorrection = Species%AuxiliarParameters%TempCorrection         


        Vol     = Cohort%BivalveCondition%Vol


        !Compute allocation fraction to maturity and reproduction (1-k), molC(reserves)/d
        Cohort%Processes%ToMaturityAndReproduction = (1 - kappa) * Cohort%Processes%Mobilization 

        !Compute maturity maintenance, molC(reserves)/d, first estimation
        Cohort%Processes%MaturityMaintenance = kJ * Tempcorrection * Me%ExternalVar%Mass(M_H,Index)

        !Compute flux to reproductionOrmaturity, JER, molC(reserves)/d
        Cohort%Processes%FluxToMatORRepr = Cohort%Processes%ToMaturityAndReproduction - Cohort%Processes%MaturityMaintenance

        if (Cohort%Processes%FluxToMatORRepr .le. 0.0) then

            Cohort%Processes%MaturityMaintenance = Cohort%Processes%ToMaturityAndReproduction

            !The organism losses maturity, molCreserves/d
            Cohort%Processes%MaturityLoss = (Me%ExternalVar%Mass(M_H,Index) - Cohort%Processes%MaturityMaintenance/    &
            (kJ* Tempcorrection)) / Me%DTDay

            !New JER
            Cohort%Processes%FluxToMatORRepr = 0.0

            Cohort%Processes%FluxToGametes   = 0.0

            Cohort%Processes%FluxToMaturity  = 0.0

        else

            Cohort%Processes%MaturityLoss = 0.0

            if (Me%ExternalVar%Mass(M_H,Index) .ge. MHp) then

                Cohort%Processes%FluxToMaturity = 0.0

                Cohort%Processes%FluxToGametes  = Cohort%Processes%FluxToMatORRepr

            else

                Cohort%Processes%FluxToMaturity = Cohort%Processes%FluxToMatORRepr

                Cohort%Processes%FluxToGametes  = 0.0

            end if

        end if 

        !Maturity Dynamics, molC(structure)/d
        Cohort%Processes%MaturityDynamics = Cohort%Processes%FluxToMaturity - Cohort%Processes%MaturityLoss

        !Matrix Mass update
        Me%ExternalVar%Mass(M_H,Index) = Me%ExternalVar%Mass(M_H,Index) +             &
        Cohort%Processes%MaturityDynamics * Me%DTDay

        if ((Me%ExternalVar%Mass(M_H,Index) .lt. MHb) .and. (Me%ExternalVar%Mass(L,Index) .gt. Lb)) then

            Cohort%Processes%DeathByStarvation = Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) /   &
            Me%DTDay !All will die from starvation

            if (Cohort%Dead .eq. 0) then 
                
                call ImposeCohortDeath (Index, Species, Cohort) !sets all proc to zero, convert mass to OM, Deadlist

                if ((Species%nCohorts .eq. 1) .and. (Cohort%Dead .eq. 1 )) then !this was the last cohort of the population...                        

                    Species%PopulationProcesses%LastCauseofDeath(3) = Cohort%Processes%DeathByStarvation
                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                    
                end if
                
                !set the state of the dead cohort to zero
                Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)      = 0.0
                Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) = 0.0

            end if

        end if

    end subroutine ComputeMaturity

    !--------------------------------------------------------------------------

    subroutine ComputeLengthAgeDynamics(Index, Species, Cohort)

        !Arguments-------------------------------------------------------------
        type(T_Species)         , pointer   :: Species
        type(T_Cohort)          , pointer   :: Cohort
        integer, intent(IN)                 :: Index

        !Local-----------------------------------------------------------------
        integer                             :: L, Age, M_V
        real                                :: L_aux, delta_M, LifeSpan, Mv

        !Begin-----------------------------------------------------------------

        L         = Cohort%StateIndex%L
        Age       = Cohort%StateIndex%Age
        M_V       = Cohort%StateIndex%M_V

        delta_M   = Species%IndividualParameters%delta_M
        LifeSpan  = Species%IndividualParameters%LifeSpan

        Mv        = Species%AuxiliarParameters%Mv

        !compute the potential new length value       
        L_aux = (Me%ExternalVar%Mass(M_V,Index)/Mv)**(1.0/3.0) / delta_M 

        Me%ExternalVar%Mass(L,Index) = max(Me%ExternalVar%Mass(L,Index),L_aux)
        Me%ExternalVar%Mass(Age,Index) = Me%ExternalVar%Mass(Age,Index) + Me%DTDay

        if (Me%ExternalVar%Mass(Age,Index) .gt. (LifeSpan * 365)) then

            Cohort%Processes%DeathByAge = Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) /   &
            Me%DTDay !All the bivalves in this cohort died from age

            if (Cohort%Dead .eq. 0 ) then 
                
                call ImposeCohortDeath (Index, Species, Cohort) !sets all proc to zero, convert mass to OM, Deadlist

                if ((Species%nCohorts .eq. 1) .and. (Cohort%Dead .eq. 1 )) then !this was the last cohort of the population...                        

                    Species%PopulationProcesses%LastCauseofDeath(1) = Cohort%Processes%DeathByAge
                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                    
                end if
                
                !set the state of the dead cohort to zero
                Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)      = 0.0
                Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) = 0.0

            end if

        end if

    end subroutine ComputeLengthAgeDynamics

    !--------------------------------------------------------------------------

    subroutine ComputeSpawning (Index, Species, Cohort)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)           :: Index
        type(T_Species),      pointer :: Species
        type(T_Cohort),       pointer :: Cohort

        !Local-----------------------------------------------------------------
        integer         :: M_R, M_V, M_E,Number 
        integer         :: POC, PON, POP 
        real            :: T 
        real            :: kap_R, GSR_MIN, GSR_SPAWN
        real            :: T_SPAWN,MIN_SPAWN_TIME, ME_0
        real            :: kJ, GSR 
        !Begin-----------------------------------------------------------------

        POC    = Me%PropIndex%POC
        PON    = Me%PropIndex%PON
        POP    = Me%PropIndex%POP


        M_R    = Cohort%StateIndex%M_R
        M_V    = Cohort%StateIndex%M_V
        M_E    = Cohort%StateIndex%M_E
        Number = Cohort%StateIndex%Number

        T  = Me%ExternalVar%Temperature(index)

        kap_R            = Species%IndividualParameters%kap_R
        GSR_MIN          = Species%IndividualParameters%GSR_MIN
        GSR_SPAWN        = Species%IndividualParameters%GSR_SPAWN 
        T_SPAWN          = Species%IndividualParameters%T_SPAWN 
        MIN_SPAWN_TIME   = Species%IndividualParameters%MIN_SPAWN_TIME 
        ME_0             = Species%IndividualParameters%ME_0   

        kJ       = Species%AuxiliarParameters%kJ 
        GSR      = Cohort%BivalveCondition%GSR 

        !Flux of gametes in the spawning event, molCreserves/d
        if ((GSR .gt. GSR_SPAWN) .and. (T .ge. T_SPAWN)) then 

            !amount of gametes that should remain in the reproduction buffer, molCreserves
            Cohort%Processes%RemainMRReproduction = GSR_MIN/(1-GSR_MIN) *         &
                                        (Me%ExternalVar%Mass(M_V,Index) + Me%ExternalVar%Mass(M_E,Index))

            !amount of gametes released in the spawning event, molCreserves/d
            Cohort%Processes%Spawning = kap_R *      &
                                        (Me%ExternalVar%Mass(M_R,Index) - Cohort%Processes%RemainMRReproduction)           &
                                        / Me%DTDay

            !losses in gametes production, just before a spawning event, molCreserves/d
            Cohort%Processes%SpawningOverhead = (1-kap_R) *        &
                                        (Me%ExternalVar%Mass(M_R,Index) - Cohort%Processes%RemainMRReproduction)  & 
                                        / Me%DTDay

            !number of gametes to be released/d
            Cohort%Processes%GametesToRelease = Cohort%Processes%Spawning/ME_0
            Species%PopulationProcesses%nSpawning = Species%PopulationProcesses%nSpawning + 1

            !number of new born/ddat
            Cohort%Processes%NewbornsThisCohort = Cohort%Processes%GametesToRelease * & 
                                        (1 - Species%IndividualParameters%m_spat)  

            !number of new borns that will not survive/d
            Cohort%Processes%NONewbornsThisCohort = Cohort%Processes%GametesToRelease * & 
                                        Species%IndividualParameters%m_spat 

            Species%PopulationProcesses%nNewborns = Species%PopulationProcesses%nNewborns + &
                                        Cohort%Processes%NewbornsThisCohort * Me%DTDay  * &
                                        Me%ExternalVar%Mass(Number, Index)
            

            !update mass, gametes that dont survive are converted into POM
            Me%ExternalVar%Mass(PON,Index) = Me%ExternalVar%Mass(PON,Index)             + &
                                        Cohort%Processes%NONewbornsThisCohort * ME_0 * Me%DTDay  * &
                                        Me%ExternalVar%Mass(Number, Index)         * &
                                        Species%SpeciesComposition%ReservesComposition%nN        * &
                                        Species%AuxiliarParameters%N_AtomicMass

            if(Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then

                if (Me%ComputeOptions%Phosphorus) then

                Me%ExternalVar%Mass(POP,Index) = Me%ExternalVar%Mass(POP,Index)     + &
                                            Cohort%Processes%NONewbornsThisCohort * ME_0 * Me%DTDay  * &
                                            Me%ExternalVar%Mass(Number, Index)         * &
                                            Species%SpeciesComposition%ReservesComposition%nP        * &
                                            Species%AuxiliarParameters%P_AtomicMass

                end if

            else !(if life)

                Me%ExternalVar%Mass(POC,Index) = Me%ExternalVar%Mass(POC,Index)     + &
                                            Cohort%Processes%NONewbornsThisCohort * ME_0 * Me%DTDay  * &
                                            Me%ExternalVar%Mass(Number, Index)         * &
                                            Species%AuxiliarParameters%C_AtomicMass
            end if !pelagic model


        else

            Cohort%Processes%Spawning             = 0.0
            Cohort%Processes%SpawningOverhead     = 0.0
            Cohort%Processes%GametesToRelease     = 0.0     
            Cohort%Processes%NewbornsThisCohort   = 0.0     
            Cohort%Processes%NONewbornsThisCohort = 0.0     

        end if
        
        

    end subroutine ComputeSpawning

    !--------------------------------------------------------------------------

    subroutine ComputeReproductionDynamics (Index, Cohort)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                             :: Index
        type(T_Cohort)             , pointer            :: Cohort

        !Local-----------------------------------------------------------------
        integer                                         :: M_R

        !Begin-----------------------------------------------------------------

        M_R      = Cohort%StateIndex%M_R

        !Reproduction Buffer Dynamics, molC(structure)/d
        Cohort%Processes%ReproductionDynamics = Cohort%Processes%FluxToGametes              - &
                                                Cohort%Processes%GametesLoss                - &
                                                Cohort%Processes%Spawning                   - &
                                                Cohort%Processes%SpawningOverhead

        !Matrix Mass update
        Me%ExternalVar%Mass(M_R,Index) = Me%ExternalVar%Mass(M_R,Index)                     + &
                                         Cohort%Processes%ReproductionDynamics * Me%DTDay

    end subroutine ComputeReproductionDynamics

    !--------------------------------------------------------------------------

    subroutine ImposeCohortDeath(Index, Species, Cohort)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                             :: Index
        type(T_Species)            , pointer            :: Species
        type(T_Cohort   )          , pointer            :: Cohort

        !Local-----------------------------------------------------------------
        integer                                         :: L, M_V, M_E, M_H, M_R    
        integer                                         :: PON, POP, POC    
        integer                                         :: Age, Number
        !Begin-----------------------------------------------------------------

        POC     = Me%PropIndex%POC
        PON     = Me%PropIndex%PON
        POP     = Me%PropIndex%POP

        L       = Cohort%StateIndex%L
        M_V     = Cohort%StateIndex%M_V
        M_E     = Cohort%StateIndex%M_E
        M_H     = Cohort%StateIndex%M_H
        M_R     = Cohort%StateIndex%M_R
        Age     = Cohort%StateIndex%Age
        Number  = Cohort%StateIndex%Number

        !bivalve biomass and what it had assimilated is converted into POM
        Me%ExternalVar%Mass(PON,Index) = Me%ExternalVar%Mass(PON,Index)                                            + &
                                        ( Me%ExternalVar%Mass(M_V,Index)                                           * &
                                        Species%SpeciesComposition%StructureComposition%nN                         + &
                                        (Me%ExternalVar%Mass(M_E,Index) + Me%ExternalVar%Mass(M_R,Index))          * &
                                        Species%SpeciesComposition%ReservesComposition%nN                          + &
                                        Cohort%Processes%Assimilation%N * Me%DTDay )                               * &
                                        Species%AuxiliarParameters%N_AtomicMass                                    * &
                                        Me%ExternalVar%Mass(Number,Index)          

        if(Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then

            if (Me%ComputeOptions%Phosphorus) then

                !bivalve biomass and what it had assimilated is converted into POM
                Me%ExternalVar%Mass(POP,Index) = Me%ExternalVar%Mass(POP,Index)                                     + &
                                                ( Me%ExternalVar%Mass(M_V,Index)                                    * &
                                                Species%SpeciesComposition%StructureComposition%nP                  + &
                                                (Me%ExternalVar%Mass(M_E,Index) + Me%ExternalVar%Mass(M_R,Index))   * &
                                                Species%SpeciesComposition%ReservesComposition%nP                   + &
                                                Cohort%Processes%Assimilation%P * Me%DTDay )                        * &
                                                Species%AuxiliarParameters%P_AtomicMass                             * &
                                                Me%ExternalVar%Mass(Number,Index)          

            end if

        else !(if life)

            !bivalve biomass and what it had assimilated is converted into POM
            Me%ExternalVar%Mass(POC,Index) = Me%ExternalVar%Mass(POC,Index)                     + &
                                            ( Me%ExternalVar%Mass(M_V,Index)                    + &
                                            Me%ExternalVar%Mass(M_E,Index)                      + &
                                            Me%ExternalVar%Mass(M_R,Index)                      + &
                                            Cohort%Processes%Assimilation%C  * Me%DTDay )       * &
                                            Species%AuxiliarParameters%C_AtomicMass             * &
                                            Me%ExternalVar%Mass(Number,Index)          

        end if !pelagic model

        Cohort%Dead = 1
        
        !Me%ExternalVar%Mass(L,Index)                   = 0.0
        Me%ExternalVar%Mass(M_V,Index)                 = 0.0
        Me%ExternalVar%Mass(M_E,Index)                 = 0.0
        Me%ExternalVar%Mass(M_H,Index)                 = 0.0
        Me%ExternalVar%Mass(M_R,Index)                 = 0.0
        Me%ExternalVar%Mass(Age,Index)                 = 0.0
        !Me%ExternalVar%Mass(Number,Index)              = 0.0        

        !Make all the processes zero       
        Cohort%Processes%ClearanceRate                 = 0.0
        Cohort%Processes%FilteredInorganic             = 0.0
        Cohort%Processes%FilteredFood%C                = 0.0
        Cohort%Processes%FilteredFood%H                = 0.0
        Cohort%Processes%FilteredFood%O                = 0.0
        Cohort%Processes%FilteredFood%N                = 0.0
        Cohort%Processes%FilteredFood%P                = 0.0

        Cohort%Processes%IngestionInorganic            = 0.0
        Cohort%Processes%IngestionFood%C               = 0.0
        Cohort%Processes%IngestionFood%H               = 0.0
        Cohort%Processes%IngestionFood%O               = 0.0
        Cohort%Processes%IngestionFood%N               = 0.0
        Cohort%Processes%IngestionFood%P               = 0.0

        Cohort%Processes%PFContributionInorganic       = 0.0
        Cohort%Processes%PFContributionFood%C          = 0.0
        Cohort%Processes%PFContributionFood%H          = 0.0
        Cohort%Processes%PFContributionFood%O          = 0.0
        Cohort%Processes%PFContributionFood%N          = 0.0
        Cohort%Processes%PFContributionFood%P          = 0.0

        Cohort%Processes%Assimilation%C                = 0.0
        Cohort%Processes%Assimilation%H                = 0.0
        Cohort%Processes%Assimilation%O                = 0.0
        Cohort%Processes%Assimilation%N                = 0.0
        Cohort%Processes%Assimilation%P                = 0.0

        Cohort%Processes%FaecesContributionInorganic   = 0.0
        Cohort%Processes%FaecesContributionFood%C      = 0.0
        Cohort%Processes%FaecesContributionFood%H      = 0.0
        Cohort%Processes%FaecesContributionFood%O      = 0.0
        Cohort%Processes%FaecesContributionFood%N      = 0.0
        Cohort%Processes%FaecesContributionFood%P      = 0.0

        Cohort%Processes%SomaticMaintenance            = 0.0
        Cohort%Processes%Mobilization                  = 0.0
        Cohort%Processes%ReservesDynamics              = 0.0
        Cohort%Processes%ToGrowthAndSomatic            = 0.0
        Cohort%Processes%ToGrowth                      = 0.0
        Cohort%Processes%GametesLoss                   = 0.0
        Cohort%Processes%StructureLoss                 = 0.0
        Cohort%Processes%SomaticMaintenanceNeeds       = 0.0
        Cohort%Processes%StructureDynamics             = 0.0
        Cohort%Processes%ToMaturityAndReproduction     = 0.0
        Cohort%Processes%MaturityMaintenance           = 0.0
        Cohort%Processes%FluxToMatORRepr               = 0.0

        Cohort%Processes%MaturityLoss                  = 0.0
        Cohort%Processes%FluxToGametes                 = 0.0
        Cohort%Processes%FluxToMaturity                = 0.0
        Cohort%Processes%MaturityDynamics              = 0.0
        Cohort%Processes%RemainMRReproduction          = 0.0
        Cohort%Processes%Spawning                      = 0.0
        Cohort%Processes%SpawningOverhead              = 0.0
        Cohort%Processes%GametesToRelease              = 0.0
        Cohort%Processes%ReproductionDynamics          = 0.0

    end subroutine ImposeCohortDeath

    !--------------------------------------------------------------------------

    subroutine ComputeInorganicFluxes (Index, Species, Cohort)

    !Arguments-------------------------------------------------------------
    integer, intent(IN)           :: Index
    type(T_Species),      pointer :: Species
    type(T_Cohort),       pointer :: Cohort


    !Local-----------------------------------------------------------------
    integer         :: AM, IP, CarbonDioxide, Oxygen 
    integer         :: Number 
    real            :: nC_CO2, nH_CO2, nO_CO2,nN_CO2, nP_CO2 
    real            :: nC_H2O,nH_H2O,nO_H2O, nN_H2O,nP_H2O
    real            :: nC_O2,nH_O2,nO_O2,nN_O2,nP_O2
    real            :: nC_NH3,nH_NH3,nO_NH3,nN_NH3,nP_NH3
    real            :: nC_PO4,nH_PO4,nO_PO4,nN_PO4,nP_PO4
    real            :: nC_Stru,nH_Stru,nO_Stru,nN_Stru,nP_Stru
    real            :: nC_Rese, nH_Rese, nO_Rese, nN_Rese,nP_Rese
    !Begin-----------------------------------------------------------------


    AM            = Me%PropIndex%AM
    IP            = Me%PropIndex%IP
    CarbonDioxide = Me%PropIndex%CarbonDioxide
    Oxygen        = Me%PropIndex%Oxygen

    Number  = Cohort%StateIndex%Number

    nC_CO2 = 1 
    nC_H2O = 0
    nC_O2  = 0
    nC_NH3 = 0
    nC_PO4 = 0
    nC_Stru= 1
    nC_Rese= 1

    nH_CO2 = 0 
    nH_H2O = 2
    nH_O2  = 0
    nH_NH3 = 3
    nH_PO4 = 0
    nH_Stru= Species%SpeciesComposition%StructureComposition%nH
    nH_Rese= Species%SpeciesComposition%ReservesComposition%nH

    nO_CO2 = 2 
    nO_H2O = 1
    nO_O2  = 2
    nO_NH3 = 0
    nO_PO4 = 4
    nO_Stru= Species%SpeciesComposition%StructureComposition%nO
    nO_Rese= Species%SpeciesComposition%ReservesComposition%nO

    nN_CO2 = 0 
    nN_H2O = 0
    nN_O2  = 0
    nN_NH3 = 1
    nN_PO4 = 0
    nN_Stru= Species%SpeciesComposition%StructureComposition%nN
    nN_Rese= Species%SpeciesComposition%ReservesComposition%nN

    nP_CO2 = 0 
    nP_H2O = 0
    nP_O2  = 0
    nP_NH3 = 0
    nP_PO4 = 1
    nP_Stru= Species%SpeciesComposition%StructureComposition%nP
    nP_Rese= Species%SpeciesComposition%ReservesComposition%nP

    !Compute Ammonia Fluxes, molN/d
    Cohort%Processes%InorganicFluxes%NH3 = -1/nN_NH3 * ( -Cohort%Processes%FilteredFood%N          + &
    Cohort%Processes%PFContributionFood%N      + &
    Cohort%Processes%FaecesContributionFood%N  + &
    Cohort%Processes%StructureDynamics           * nN_Stru   + &
    Cohort%Processes%ReservesDynamics            * nN_Rese   + &
    Cohort%Processes%ReproductionDynamics        * nN_Rese   + &
    (Species%IndividualParameters%MEb             * nN_Rese   + &
    Species%IndividualParameters%MVb             * nN_Stru)  * &
    Cohort%Processes%NewbornsThisCohort        + &
    Cohort%Processes%NONewbornsThisCohort      * &
    Species%IndividualParameters%ME_0 * nN_Rese )





    !Compute Water Fluxes, molH2O/d
    Cohort%Processes%InorganicFluxes%H2O = -1/nH_H2O * ( -Cohort%Processes%FilteredFood%H         + &
    Cohort%Processes%InorganicFluxes%NH3         * nH_NH3    + &
    Cohort%Processes%PFContributionFood%H      + &
    Cohort%Processes%FaecesContributionFood%H  + &
    Cohort%Processes%StructureDynamics           * nH_Stru   + &
    Cohort%Processes%ReservesDynamics            * nH_Rese   + &
    Cohort%Processes%ReproductionDynamics        * nH_Rese   + &
    (Species%IndividualParameters%MEb             * nH_Rese   + &
    Species%IndividualParameters%MVb             * nH_Stru)  * &
    Cohort%Processes%NewbornsThisCohort        + &
    Cohort%Processes%NONewbornsThisCohort      * &
    Species%IndividualParameters%ME_0 * nH_Rese )

    !Compute CO2, molCO2/d
    Cohort%Processes%InorganicFluxes%CO2 = -1/nC_CO2 * ( -Cohort%Processes%FilteredFood%C         + &
    Cohort%Processes%PFContributionFood%C      + &
    Cohort%Processes%FaecesContributionFood%C  + &
    Cohort%Processes%StructureDynamics           * nC_Stru   + &
    Cohort%Processes%ReservesDynamics            * nC_Rese   + &
    Cohort%Processes%ReproductionDynamics        * nC_Rese   + &
    (Species%IndividualParameters%MEb             * nC_Rese   + &
    Species%IndividualParameters%MVb             * nC_Stru)  * &
    Cohort%Processes%NewbornsThisCohort        + &
    Cohort%Processes%NONewbornsThisCohort      * &
    Species%IndividualParameters%ME_0 * nC_Rese )

    if (Me%ComputeOptions%Phosphorus) then

    !Compute Phosphate Fluxes, molP/d
    Cohort%Processes%InorganicFluxes%PO4 = -1/nP_PO4 * ( -Cohort%Processes%FilteredFood%P         + &
    Cohort%Processes%PFContributionFood%P      + &
    Cohort%Processes%FaecesContributionFood%P  + &
    Cohort%Processes%StructureDynamics           * nP_Stru   + &
    Cohort%Processes%ReservesDynamics            * nP_Rese   + &
    Cohort%Processes%ReproductionDynamics        * nP_Rese   + &
    (Species%IndividualParameters%MEb             * nP_Rese   + &
    Species%IndividualParameters%MVb             * nP_Stru)  * &
    Cohort%Processes%NewbornsThisCohort        + &
    Cohort%Processes%NONewbornsThisCohort      * &
    Species%IndividualParameters%ME_0 * nP_Rese )

    !Compute Oxygen Fluxes, molO2/d
    Cohort%Processes%InorganicFluxes%O2  = -1/nO_O2 * ( -Cohort%Processes%FilteredFood%O          + &
    Cohort%Processes%InorganicFluxes%PO4         * nO_PO4    + &
    Cohort%Processes%InorganicFluxes%CO2         * nO_H2O    + &
    Cohort%Processes%InorganicFluxes%H2O         * nO_CO2    + &
    Cohort%Processes%PFContributionFood%O      + &
    Cohort%Processes%FaecesContributionFood%O  + &
    Cohort%Processes%StructureDynamics           * nO_Stru   + &
    Cohort%Processes%ReservesDynamics            * nO_Rese   + &
    Cohort%Processes%ReproductionDynamics        * nO_Rese   + &
    (Species%IndividualParameters%MEb             * nO_Rese   + &
    Species%IndividualParameters%MVb             * nO_Stru)  * &
    Cohort%Processes%NewbornsThisCohort        + &
    Cohort%Processes%NONewbornsThisCohort      * &
    Species%IndividualParameters%ME_0 * nO_Rese )

    else !no P

    !Compute Oxygen Fluxes, molO2/d
    Cohort%Processes%InorganicFluxes%O2 = -1/nO_O2 * ( -Cohort%Processes%FilteredFood%O            + &
    Cohort%Processes%InorganicFluxes%CO2         * nO_H2O    + &
    Cohort%Processes%InorganicFluxes%H2O         * nO_CO2    + &
    Cohort%Processes%PFContributionFood%O      + &
    Cohort%Processes%FaecesContributionFood%O  + &
    Cohort%Processes%StructureDynamics           * nO_Stru   + &
    Cohort%Processes%ReservesDynamics            * nO_Rese   + &
    Cohort%Processes%ReproductionDynamics        * nO_Rese   + &
    (Species%IndividualParameters%MEb            * nO_Rese   + &
    Species%IndividualParameters%MVb             * nO_Stru)  * &
    Cohort%Processes%NewbornsThisCohort        + &
    Cohort%Processes%NONewbornsThisCohort      * &
    Species%IndividualParameters%ME_0            * nO_Rese )
    end if


    !update mass, g    
    Me%ExternalVar%Mass(AM,Index) = Me%ExternalVar%Mass(AM,Index)           + &
    (Cohort%Processes%InorganicFluxes%NH3 *   &
    Species%AuxiliarParameters%N_AtomicMass)            *   &
    Me%ExternalVar%Mass(Number, Index) * Me%DTDay  


    Me%ExternalVar%Mass(CarbonDioxide,Index) = Me%ExternalVar%Mass(CarbonDioxide,Index)   + &
    (Cohort%Processes%InorganicFluxes%CO2 *   &
    Species%AuxiliarParameters%C_AtomicMass)            *   &
    Me%ExternalVar%Mass(Number, Index) * Me%DTDay  

    Me%ExternalVar%Mass(Oxygen,Index) = Me%ExternalVar%Mass(Oxygen,Index)   + &
    (Cohort%Processes%InorganicFluxes%O2  *   &
    Species%AuxiliarParameters%O_AtomicMass)            *   &
    Me%ExternalVar%Mass(Number, Index) * Me%DTDay  

    if (Me%ComputeOptions%Phosphorus) then

    !Mass Uptade
    Me%ExternalVar%Mass(IP,Index) = Me%ExternalVar%Mass(IP,Index)   + &
    (Cohort%Processes%InorganicFluxes%PO4 *   &
    Species%AuxiliarParameters%P_AtomicMass)            *   &
    Me%ExternalVar%Mass(Number, Index) * Me%DTDay  
    end if

    end subroutine ComputeInorganicFluxes

    !--------------------------------------------------------------------------

    subroutine ComputeNaturalMortality (Index)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                         :: Index

        !Local-----------------------------------------------------------------
        type(T_Species)             , pointer       :: Species
        type(T_Cohort)              , pointer       :: Cohort
        integer                                     :: Number, M_V, M_E, M_R   
        integer                                     :: PON, POC, POP   

        !Begin-----------------------------------------------------------------

        POC     = Me%PropIndex%POC
        PON     = Me%PropIndex%PON
        POP     = Me%PropIndex%POP

        Species => Me%FirstSpecies
d1:     do while(associated(Species))

            Cohort => Species%FirstCohort
d2:         do while(associated(Cohort))

                M_V     = Cohort%StateIndex%M_V
                M_E     = Cohort%StateIndex%M_E
                M_R     = Cohort%StateIndex%M_R
                Number  = Cohort%StateIndex%Number

                if (Cohort%Dead .eq. 0 ) then

                    !Natural mortality, #/d
                    Cohort%Processes%DeathByNatural = Me%ExternalVar%Mass(Number,Index)             * &
                                                      Species%IndividualParameters%m_natural
                                                      

                    !update the number of organisms in mass matrix
                    Me%ExternalVar%Mass(Number,Index) = Me%ExternalVar%Mass(Number,Index)           - &
                                                        (Cohort%Processes%DeathByNatural * Me%DTDay) 


                    if (Species%nCohorts .eq. 1) then                         
                        
                        Species%PopulationProcesses%LastCauseofDeath(4) = Cohort%Processes%DeathByNatural !Natural mortality
                        Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                    
                    end if


                    !update POM again
                    Me%ExternalVar%Mass(PON,Index) = Me%ExternalVar%Mass(PON,Index)                                   + &
                                                    ( Me%ExternalVar%Mass(M_V,Index)                                  * &
                                                    Species%SpeciesComposition%StructureComposition%nN                + &
                                                    (Me%ExternalVar%Mass(M_E,Index) + Me%ExternalVar%Mass(M_R,Index)) * &
                                                    Species%SpeciesComposition%ReservesComposition%nN )               * &
                                                    Species%AuxiliarParameters%N_AtomicMass                           * &
                                                    Cohort%Processes%DeathByNatural * Me%DTDay           

                    if(Me%ComputeOptions%PelagicModel .eq. WaterQualityModel) then


                        if (Me%ComputeOptions%Phosphorus) then

                            Me%ExternalVar%Mass(POP,Index) = Me%ExternalVar%Mass(POP,Index)                           + &
                                                    ( Me%ExternalVar%Mass(M_V,Index)                                  * &
                                                    Species%SpeciesComposition%StructureComposition%nP                + &
                                                    (Me%ExternalVar%Mass(M_E,Index) + Me%ExternalVar%Mass(M_R,Index)) * &
                                                    Species%SpeciesComposition%ReservesComposition%nP )               * &
                                                    Species%AuxiliarParameters%P_AtomicMass                           * &
                                                    Cohort%Processes%DeathByNatural * Me%DTDay           

                        end if

                    else !(if life)


                        Me%ExternalVar%Mass(POC,Index) = Me%ExternalVar%Mass(POC,Index)              + &
                                                        ( Me%ExternalVar%Mass(M_V,Index)             + &
                                                        Me%ExternalVar%Mass(M_E,Index)               + &
                                                        Me%ExternalVar%Mass(M_R,Index) )             * &
                                                        Cohort%Processes%DeathByNatural * Me%DTDay

                    end if !pelagic model

                end if !its alive             

                Cohort => Cohort%Next
            end do d2

            Species => Species%Next
        end do d1

    end subroutine ComputeNaturalMortality

    !--------------------------------------------------------------------------

    subroutine ComputePredation (Index, CheckIfOpenPoint)

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                 :: Index
        integer, intent(IN)                 :: CheckIfOpenPoint


        !Local-----------------------------------------------------------------
        type(T_Species)          , pointer  :: Species
        type(T_Cohort)           , pointer  :: Cohort
        character(StringLength)             :: PredatorName


        !Begin-----------------------------------------------------------------

        call CheckFeedingByPredator (CheckIfOpenPoint)

        PredatorName = 'shrimp'
        call ComputePredationByPredator (Index, PredatorName, Me%PropIndex%Shrimp)

        PredatorName = 'crab'
        call ComputePredationByPredator (Index, PredatorName, Me%PropIndex%Crab)

        PredatorName = 'oystercatcher'
        call ComputePredationByPredator (Index, PredatorName, Me%PropIndex%OysterCatcher)

        PredatorName = 'eider duck'
        call ComputePredationByPredator (Index, PredatorName, Me%PropIndex%EiderDuck)

        PredatorName = 'herring gull'
        call ComputePredationByPredator (Index, PredatorName, Me%PropIndex%HerringGull)

        Species => Me%FirstSpecies
d1:     do while(associated(Species))

            Cohort => Species%FirstCohort
d2:         do while(associated(Cohort))

                if (Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) .lt. Me%MinNumber) then

                    if (Cohort%Dead .eq. 0 ) then 
                    
                        call ImposeCohortDeath (Index, Species, Cohort) !sets all proc to zero, convert mass to OM, Deadlist

                        if ((Species%nCohorts .eq. 1) .and. (Cohort%Dead .eq. 1 )) then 
                        !if the last cohort in the population                          

                            Cohort%Processes%DeathByLowNumbers = Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) /   &
                                                   Me%DTDay !All die from 'low numbers'
                            
                            Species%PopulationProcesses%LastCauseofDeath(10) = Cohort%Processes%DeathByLowNumbers

                            Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                            

                        end if
                        
                        !set the state of the dead cohort to zero
                        Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)      = 0.0
                        Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index) = 0.0
                        
                    end if

                end if

                Cohort => Cohort%Next
            end do d2

        Species => Species%Next
        end do d1

    end subroutine ComputePredation

    !--------------------------------------------------------------------------

    subroutine CheckFeedingByPredator (CheckIfOpenPoint)

    !Arguments-------------------------------------------------------------
    integer, intent(IN)             :: CheckIfOpenPoint

    !Local-----------------------------------------------------------------
    type(T_Species)  ,      pointer :: Species
    type(T_Predator) ,      pointer :: Predator

    !Begin-----------------------------------------------------------------

    Species => Me%FirstSpecies
    d1:     do while(associated(Species))

    Predator => Species%FirstPredator
    d2:     do while(associated(Predator))

    Predator%Feeding = .false.

    if (Predator%Feeding_Time .eq. 1) Predator%Feeding = .true.

    if ((Predator%Feeding_Time .eq. 2) .and. (CheckIfOpenPoint .ne. OpenPoint)) Predator%Feeding = .true.

    if ((Predator%Feeding_Time .eq. 3) .and. (CheckIfOpenPoint .eq. OpenPoint)) Predator%Feeding = .true.

    Predator => Predator%Next
    end do d2

    Species => Species%Next
    end do d1


    end subroutine CheckFeedingByPredator

    !--------------------------------------------------------------------------

    subroutine ComputePredationByPredator (Index, PredatorName, PredatorIndex)

        !Arguments-------------------------------------------------------------
        integer  , intent(IN)           :: Index
        character(StringLength), intent(IN)           :: PredatorName
        integer  , intent(IN)           :: PredatorIndex

        !Local-----------------------------------------------------------------
        type(T_Species)  ,      pointer :: Species
        type(T_Cohort)   ,      pointer :: Cohort
        type(T_Predator) ,      pointer :: Predator
        real:: Tref, TA, TL, TH, TAL, TAH, T
        real:: TotalPreyAvailable
        real:: PotentialCohortPredation, ThisCohortPredation
        integer           :: Number, L

        !Begin-----------------------------------------------------------------

        !Compute the total number of organisms available for this predator        
        TotalPreyAvailable = 0

        Species => Me%FirstSpecies
d1:     do while(associated(Species))

            Predator => Species%FirstPredator
d2:         do while(associated(Predator))

                if ((Predator%ID%Name .eq. PredatorName) .and. Predator%Feeding) then

                    !Compute the number of prey available
                    Cohort => Species%FirstCohort
d3:                 do while(associated(Cohort))

                        if (Cohort%Dead .eq. 0 ) then

                            if ((Me%ExternalVar%Mass(Cohort%StateIndex%L,Index) .ge. Predator%MinPreySize) .and.  &
                                (Me%ExternalVar%Mass(Cohort%StateIndex%L,Index) .le. Predator%MaxPreySize)  ) then

                                !#/m3
                                TotalPreyAvailable = TotalPreyAvailable + Me%ExternalVar%Mass(Cohort%StateIndex%Number,Index)

                            end if
                        
                        end if

                        Cohort => Cohort%Next
                    end do d3

                end if

                Predator => Predator%Next
            end do d2

            Species => Species%Next
        end do d1

        !Compute how much will be predated by each cohort, depending on its relative abundance, in numbers
        Species => Me%FirstSpecies
d4:     do while(associated(Species))

            Predator => Species%FirstPredator
d5:         do while(associated(Predator))

                if ((Predator%ID%Name .eq. PredatorName) .and. Predator%Feeding) then

                    !Temperature Correction factor for the predator
                    Tref  = Predator%P_Tref
                    TA    = Predator%P_TA
                    TL    = Predator%P_TL
                    TH    = Predator%P_TH
                    TAL   = Predator%P_TAL
                    TAH   = Predator%P_TAH

                    !K, Actual Temperature, oC to K
                    T = Me%ExternalVar%Temperature(index) + 273

                    if (Predator%CORRECT_TEMP .eq. 0.0) then

                        Predator%TempCorrection  = 1.0

                    else
                        if (Predator%SIMPLE_TEMP .eq. 0.0) then
                        
                            Predator%TempCorrection  = exp(TA/Tref-TA/T)                                   * &
                                                    (1.0 + exp(TAL/Tref - TAL/TL) + exp(TAH/TH-TAH/Tref))  / &
                                                    (1.0 + exp(TAL/T - TAL/TL) + exp(TAH/TH-TAH/T))
                                                
                        else 
                                    
                            Predator%TempCorrection  = exp(TA/Tref-TA/T)  
                        
                        end if
                        
                    end if

                    !Compute the predation on this cohort
                    Cohort => Species%FirstCohort
d6:                 do while(associated(Cohort))

                        if (Cohort%Dead .eq. 0) then

                            Number = Cohort%StateIndex%Number
                            L      = Cohort%StateIndex%L

                            if ((Me%ExternalVar%Mass(L,Index) .ge. Predator%MinPreySize) .and.  &
                                (Me%ExternalVar%Mass(L,Index) .le. Predator%MaxPreySize) .and.  &
                                 Me%ExternalVar%Mass(Number,Index) .gt. 0.0 ) then

                                if (TotalPreyAvailable .eq. 0.0) then
                                    Predator%TotalFeeding_Rate = 0.0
                                    PotentialCohortPredation  = 0.0
                                else

                                    !Compute how much will be predated from this cohort
                                    select case (Predator%Feeding_Units)

                                    case (1) !#/d.ind, crab

                                        !#prey/d.m3 = #prey/d.ind * ind/m3
                                        Predator%TotalFeeding_Rate = Predator%Feeding_Rate                                     * &
                                                                     Me%ExternalVar%Mass(PredatorIndex,Index)

                                        !#prey/d.m3
                                        PotentialCohortPredation = Me%ExternalVar%Mass(Number,Index) / TotalPreyAvailable      * &
                                                                   Predator%TotalFeeding_Rate * Predator%TempCorrection        * &
                                                                   Predator%Diet

                                    case (2) !AFDW/d.ind, birds

                                        !molC/d.m3 = gAFDW/d.ind * gdw/gafdw * gC/gdw * molC/gC * ind/m3  
                                        Predator%TotalFeeding_Rate = Predator%Feeding_Rate/Predator%AfdwToC/Predator%AfdwToC/12 * &
                                                                     Me%ExternalVar%Mass(PredatorIndex,Index)

                                        !molC/d.m3
                                        PotentialCohortPredation = Me%ExternalVar%Mass(Number,Index) / TotalPreyAvailable       * &
                                                                   Predator%TotalFeeding_Rate * Predator%TempCorrection         * &
                                                                   Predator%Diet

                                        !#prey/d.m3
                                        PotentialCohortPredation = PotentialCohortPredation / Cohort%BivalveCondition%TotalmolC 

                                    case (3) !J/cm2.d.ind, shrimps

                                        !J/d.m3 = J/cm2.d.ind * cm2 * ind/m3 
                                        Predator%TotalFeeding_Rate = Predator%Feeding_Rate * Predator%PredatorSize ** 2         * &
                                                                     Me%ExternalVar%Mass(PredatorIndex,Index)

                                        !J/d.m3
                                        PotentialCohortPredation = Me%ExternalVar%Mass(Number,Index) / TotalPreyAvailable       * &
                                                                   Predator%TotalFeeding_Rate * Predator%TempCorrection         * &
                                                                   Predator%Diet

                                        !#prey/d.m3, mu_E = mu_V 
                                        PotentialCohortPredation = PotentialCohortPredation / Species%IndividualParameters%mu_E / &
                                                                   Cohort%BivalveCondition%TotalmolC
                                    
                                    end select
                                end if !TotalPreyAvailable==0

                                !Restrict ThisCohortPredation based on the number of individuals in this cohort, #
                                ThisCohortPredation = min(Me%ExternalVar%Mass(Number,Index),PotentialCohortPredation * Me%DTDay) 

                                !Store how much is predated by each predator
                                if (Predator%ID%Name .eq. 'shrimp') then  
                                    
                                    Cohort%Processes%PredationByShrimps =  ThisCohortPredation/Me%DTday
                                    
                                    Species%PopulationProcesses%LastCauseofDeath(5) = Cohort%Processes%PredationByShrimps
                                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                                    
                                   
                                end if

                                if (Predator%ID%Name .eq. 'crab') then  
                                    
                                    Cohort%Processes%PredationByCrabs =  ThisCohortPredation/Me%DTday
                                    
                                    Species%PopulationProcesses%LastCauseofDeath(6) = Cohort%Processes%PredationByCrabs
                                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)

                                end if

                                if (Predator%ID%Name .eq. 'oystercatcher') then  
                                    
                                    Cohort%Processes%PredationByOysterCatchers =  ThisCohortPredation/Me%DTday
                                    
                                    Species%PopulationProcesses%LastCauseofDeath(7) = Cohort%Processes%PredationByOysterCatchers
                                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                                
                                end if

                                if (Predator%ID%Name .eq. 'eider duck') then  
                                    
                                    Cohort%Processes%PredationByEiderDucks =  ThisCohortPredation/Me%DTday
                                    
                                    Species%PopulationProcesses%LastCauseofDeath(8) = Cohort%Processes%PredationByEiderDucks
                                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                                    
                                end if

                                if (Predator%ID%Name .eq. 'herring gull') then 
                                 
                                    Cohort%Processes%PredationByHerringGull =  ThisCohortPredation/Me%DTday
                                    
                                    Species%PopulationProcesses%LastCauseofDeath(9) = Cohort%Processes%PredationByHerringGull
                                    Species%PopulationProcesses%LastLength          = Me%ExternalVar%Mass(Cohort%StateIndex%L,Index)
                                    
                                end if

                                !Update Mass
                                Me%ExternalVar%Mass(Number,Index) = Me%ExternalVar%Mass(Number,Index) - ThisCohortPredation    

                            end if !if the cohort have the right size for this predator

                        end if
                        Cohort => Cohort%Next
                    end do d6
                end if !it is this predator

                Predator => Predator%Next
            end do d5

            Species => Species%Next
        end do d4

    end subroutine ComputePredationByPredator

    !--------------------------------------------------------------------------

    subroutine ComputePopulationVariables (Index)

        !Arguments-------------------------------------------------------------
        type(T_Species),               pointer  :: Species
        type(T_Cohort),                pointer  :: Cohort
        integer, intent(IN)                     :: Index

        !Local-----------------------------------------------------------------
        type(T_PopulationProcesses),   pointer  :: PopulationProcesses
        integer                                 :: L, Number 
        !Begin-----------------------------------------------------------------

        Species => Me%FirstSpecies
d1:     do while(associated(Species))
            
            PopulationProcesses => Species%PopulationProcesses

            PopulationProcesses%TN          = 0.0
            PopulationProcesses%NCoh        = 0.0
            PopulationProcesses%TBio        = 0.0
            PopulationProcesses%Cr          = 0.0
            PopulationProcesses%Fil         = 0.0
            PopulationProcesses%Ing         = 0.0
            PopulationProcesses%Ass         = 0.0
            PopulationProcesses%CO2         = 0.0
            PopulationProcesses%H2O         = 0.0
            PopulationProcesses%O           = 0.0
            PopulationProcesses%NH3         = 0.0
            PopulationProcesses%PO4         = 0.0
            PopulationProcesses%m_A         = 0.0
            PopulationProcesses%m_O         = 0.0
            PopulationProcesses%m_F         = 0.0
            PopulationProcesses%m_nat       = 0.0
            PopulationProcesses%m_shr       = 0.0
            PopulationProcesses%m_cra       = 0.0
            PopulationProcesses%m_oys       = 0.0
            PopulationProcesses%m_duck      = 0.0
            PopulationProcesses%m_gull      = 0.0
            PopulationProcesses%m_low       = 0.0
            PopulationProcesses%Massm_A     = 0.0
            PopulationProcesses%Massm_O     = 0.0
            PopulationProcesses%Massm_F     = 0.0
            PopulationProcesses%Massm_nat   = 0.0
            PopulationProcesses%Massm_shr   = 0.0
            PopulationProcesses%Massm_cra   = 0.0
            PopulationProcesses%Massm_oys   = 0.0
            PopulationProcesses%Massm_duck  = 0.0
            PopulationProcesses%Massm_gull  = 0.0
            PopulationProcesses%Massm_low   = 0.0
            PopulationProcesses%TNField     = 0.0
            PopulationProcesses%MaxLength   = 0.0

            Cohort => Species%FirstCohort
d2:         do while(associated(Cohort))

                Number = Cohort%StateIndex%Number    
                L      = Cohort%StateIndex%L        


                PopulationProcesses%TN        = PopulationProcesses%TN          + &
                                                      Me%ExternalVar%Mass(Number,Index)
                                                        
                PopulationProcesses%NCoh      = PopulationProcesses%NCoh        + 1
                      
                PopulationProcesses%TBio      = PopulationProcesses%TBio        + &
                                              Cohort%BivalveCondition%TotalmolC * Me%ExternalVar%Mass(Number,Index)
                                                
                PopulationProcesses%Cr        = PopulationProcesses%Cr          + &
                                              Cohort%Processes%ClearanceRate * Me%ExternalVar%Mass(Number,Index)
                                                
                PopulationProcesses%Fil       = PopulationProcesses%Fil         + &
                                              Cohort%Processes%FilteredFood%C * Me%ExternalVar%Mass(Number,Index) 
                                                   
                PopulationProcesses%Ing       = PopulationProcesses%Ing         + &
                                              Cohort%Processes%IngestionFood%C * Me%ExternalVar%Mass(Number,Index)
                                                    
                PopulationProcesses%Ass       = PopulationProcesses%Ass         + &
                                              Cohort%Processes%Assimilation%C * Me%ExternalVar%Mass(Number,Index) 
                                                   
                PopulationProcesses%CO2       = PopulationProcesses%CO2         + &
                                              Cohort%Processes%InorganicFluxes%CO2 * Me%ExternalVar%Mass(Number,Index) 
                                                   
                PopulationProcesses%H2O       = PopulationProcesses%H2O         + &
                                              Cohort%Processes%InorganicFluxes%H2O * Me%ExternalVar%Mass(Number,Index) 
                                                     
                PopulationProcesses%O         = PopulationProcesses%O           + &
                                              Cohort%Processes%InorganicFluxes%O2 * Me%ExternalVar%Mass(Number,Index)  
                                                    
                PopulationProcesses%NH3       = PopulationProcesses%NH3         + &
                                              Cohort%Processes%InorganicFluxes%NH3 * Me%ExternalVar%Mass(Number,Index)
                                                      
                PopulationProcesses%PO4       = PopulationProcesses%PO4         + &
                                              Cohort%Processes%InorganicFluxes%PO4 * Me%ExternalVar%Mass(Number,Index) 
                                                         
                PopulationProcesses%m_A       = PopulationProcesses%m_A         + &
                                              Cohort%Processes%DeathByAge * Me%DTday
                                                         
                PopulationProcesses%m_O       = PopulationProcesses%m_O       + &
                                              Cohort%Processes%DeathByOxygen * Me%DTday
                                                  
                PopulationProcesses%m_F       = PopulationProcesses%m_F        + &
                                              Cohort%Processes%DeathByStarvation * Me%DTday
                                                  
                PopulationProcesses%m_nat     = PopulationProcesses%m_nat      + &
                                              Cohort%Processes%DeathByNatural * Me%DTday
                                                  
                PopulationProcesses%m_shr     = PopulationProcesses%m_shr       + &
                                              Cohort%Processes%PredationByShrimps * Me%DTday
                                                  
                PopulationProcesses%m_cra     = PopulationProcesses%m_cra       + &
                                              Cohort%Processes%PredationByCrabs * Me%DTday
                                                  
                PopulationProcesses%m_oys     = PopulationProcesses%m_oys       + &
                                              Cohort%Processes%PredationByOysterCatchers * Me%DTday
                                                  
                PopulationProcesses%m_duck    = PopulationProcesses%m_duck      + &
                                              Cohort%Processes%PredationByEiderDucks * Me%DTday 
                                                  
                PopulationProcesses%m_gull    = PopulationProcesses%m_gull     + &
                                              Cohort%Processes%PredationByHerringGull * Me%DTday
                                                  
                PopulationProcesses%m_low     = PopulationProcesses%m_low      + &
                                              Cohort%Processes%DeathByLowNumbers * Me%DTday
                                                                                               
                PopulationProcesses%Massm_A   = PopulationProcesses%Massm_A     + &
                                              Cohort%Processes%DeathByAge* Me%DTday * Cohort%BivalveCondition%TotalmolC
                                                          
                PopulationProcesses%Massm_O   = PopulationProcesses%Massm_O     + &
                                              Cohort%Processes%DeathByOxygen* Me%DTday * Cohort%BivalveCondition%TotalmolC
                                                          
                PopulationProcesses%Massm_F   = PopulationProcesses%Massm_F     + &
                                              Cohort%Processes%DeathByStarvation* Me%DTday * Cohort%BivalveCondition%TotalmolC
                                                          
                PopulationProcesses%Massm_nat = PopulationProcesses%Massm_nat   + &
                                              Cohort%Processes%DeathByNatural* Me%DTday * Cohort%BivalveCondition%TotalmolC
                                                          
                PopulationProcesses%Massm_shr = PopulationProcesses%Massm_shr   + &
                                              Cohort%Processes%PredationByShrimps* Me%DTday * Cohort%BivalveCondition%TotalmolC 
                                                         
                PopulationProcesses%Massm_cra = PopulationProcesses%Massm_cra   + &
                                              Cohort%Processes%PredationByCrabs* Me%DTday * Cohort%BivalveCondition%TotalmolC
                                                          
                PopulationProcesses%Massm_oys = PopulationProcesses%Massm_oys   + &
                                              Cohort%Processes%PredationByOysterCatchers* Me%DTday * &
                                              Cohort%BivalveCondition%TotalmolC 
                                                         
                PopulationProcesses%Massm_duck= PopulationProcesses%Massm_duck  + &
                                              Cohort%Processes%PredationByEiderDucks* Me%DTday *     &
                                              Cohort%BivalveCondition%TotalmolC
                                                          
                PopulationProcesses%Massm_gull= PopulationProcesses%Massm_gull  + &
                                              Cohort%Processes%PredationByHerringGull* Me%DTday * Cohort%BivalveCondition%TotalmolC
                                                          
                PopulationProcesses%Massm_low = PopulationProcesses%Massm_low   + &
                                              Cohort%Processes%DeathByLowNumbers* Me%DTday * Cohort%BivalveCondition%TotalmolC
                
                if (Me%ExternalVar%Mass(L,Index) .ge. 0.1) then
                    PopulationProcesses%TNField = PopulationProcesses%TNField + Me%ExternalVar%Mass(Number,Index)
                end if
                
                PopulationProcesses%MaxLength = max(PopulationProcesses%MaxLength,Me%ExternalVar%Mass(L,Index))
                
                Cohort => Cohort%Next
            end do d2            

            if (PopulationProcesses%TN .ne. 0.0) then
            
                PopulationProcesses%nInstantsForAverage = PopulationProcesses%nInstantsForAverage + 1
                
                !Product of mortalities in numbers
                if (1.-PopulationProcesses%m_A /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(1)  = PopulationProcesses%SumLogAllMortalityInNumbers(1)   + &
                                                            log10(1.-PopulationProcesses%m_A /PopulationProcesses%TNStartTimeStep) 
                end if
                
                if (1.-PopulationProcesses%m_O /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(2)  = PopulationProcesses%SumLogAllMortalityInNumbers(2)   + &
                                                            log10(1.-PopulationProcesses%m_O/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_F /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(3)  = PopulationProcesses%SumLogAllMortalityInNumbers(3)   + &
                                                            log10(1.-PopulationProcesses%m_F/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_nat /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(4)  = PopulationProcesses%SumLogAllMortalityInNumbers(4)   + &
                                                            log10(1.-PopulationProcesses%m_nat/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_shr /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(5)  = PopulationProcesses%SumLogAllMortalityInNumbers(5)   + &
                                                            log10(1.-PopulationProcesses%m_shr/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_cra /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(6)  = PopulationProcesses%SumLogAllMortalityInNumbers(6)   + &
                                                            log10(1.-PopulationProcesses%m_cra/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_oys /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(7)  = PopulationProcesses%SumLogAllMortalityInNumbers(7)   + &
                                                            log10(1.-PopulationProcesses%m_oys/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_duck /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(8)  = PopulationProcesses%SumLogAllMortalityInNumbers(8)   + &
                                                            log10(1.-PopulationProcesses%m_duck/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_gull /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(9)  = PopulationProcesses%SumLogAllMortalityInNumbers(9)   + &
                                                            log10(1.-PopulationProcesses%m_gull/PopulationProcesses%TNStartTimeStep)
                end if

                if (1.-PopulationProcesses%m_low /PopulationProcesses%TNStartTimeStep .gt. 0.0) then 
                    PopulationProcesses%SumLogAllMortalityInNumbers(10) = PopulationProcesses%SumLogAllMortalityInNumbers(10)  + &
                                                            log10(1.-PopulationProcesses%m_low/PopulationProcesses%TNStartTimeStep)
                end if

                                                        
                !average mortality in numbers
                PopulationProcesses%AverageMortalityInNumbers(1 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(1)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(2 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(2)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(3 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(3)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(4 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(4)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(5 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(5)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(6 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(6)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(7 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(7)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(8 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(8)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(9 )  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(9)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday 
                PopulationProcesses%AverageMortalityInNumbers(10)  = (1.-10**(PopulationProcesses%SumLogAllMortalityInNumbers(10)*&
                                                                    (1./PopulationProcesses%nInstantsForAverage))) / Me%DTday
            
                !Sum of mortalities in mass
                PopulationProcesses%SumAllMortalityInMass(1)  = PopulationProcesses%SumAllMortalityInMass(1) + &
                                                            PopulationProcesses%Massm_A    
                PopulationProcesses%SumAllMortalityInMass(2)  = PopulationProcesses%SumAllMortalityInMass(2) + &
                                                            PopulationProcesses%Massm_O    
                PopulationProcesses%SumAllMortalityInMass(3)  = PopulationProcesses%SumAllMortalityInMass(3) + &
                                                            PopulationProcesses%Massm_F    
                PopulationProcesses%SumAllMortalityInMass(4)  = PopulationProcesses%SumAllMortalityInMass(4) + &
                                                            PopulationProcesses%Massm_nat  
                PopulationProcesses%SumAllMortalityInMass(5)  = PopulationProcesses%SumAllMortalityInMass(5) + &
                                                            PopulationProcesses%Massm_shr  
                PopulationProcesses%SumAllMortalityInMass(6)  = PopulationProcesses%SumAllMortalityInMass(6) + &
                                                            PopulationProcesses%Massm_cra  
                PopulationProcesses%SumAllMortalityInMass(7)  = PopulationProcesses%SumAllMortalityInMass(7) + &
                                                            PopulationProcesses%Massm_oys  
                PopulationProcesses%SumAllMortalityInMass(8)  = PopulationProcesses%SumAllMortalityInMass(8) + &
                                                            PopulationProcesses%Massm_duck 
                PopulationProcesses%SumAllMortalityInMass(9)  = PopulationProcesses%SumAllMortalityInMass(9) + &
                                                            PopulationProcesses%Massm_gull 
                PopulationProcesses%SumAllMortalityInMass(10) = PopulationProcesses%SumAllMortalityInMass(10)+ &
                                                            PopulationProcesses%Massm_low  
    

            end if !tn>0
            
            Species => Species%Next
        end do d1

    end subroutine ComputePopulationVariables

    !--------------------------------------------------------------------------

    subroutine WriteOutput (Index)

        !Arguments-------------------------------------------------------------
        type(T_Species),      pointer :: Species
        type(T_Cohort),       pointer :: Cohort
        integer, intent(IN)           :: Index

        !Local-----------------------------------------------------------------
        integer         :: M_V, M_E, M_H, M_R
        integer         :: L, Age, Number 
        real            :: Year, Month, Day, hour, minute, second

        !Begin-----------------------------------------------------------------

        call ExtractDate(Me%CurrentTime, Year, Month, Day, hour, minute, second)

        Species => Me%FirstSpecies
d1:     do while(associated(Species))

            if (Species%CohortOutput) then

                Cohort => Species%FirstCohort
d2:             do while(associated(Cohort))

                    M_V     = Cohort%StateIndex%M_V
                    M_E     = Cohort%StateIndex%M_E
                    M_H     = Cohort%StateIndex%M_H
                    M_R     = Cohort%StateIndex%M_R
                    L       = Cohort%StateIndex%L
                    Age     = Cohort%StateIndex%Age
                    Number  = Cohort%StateIndex%Number

                    !  header
                    !        write(Cohort%CohortOutput%Unit, 101)trim(adjustl(" YY1 MM2 DD3 hh4 mm5 ss6 "   // &
                    !           " Number7 ME8 MV9 MH10 MR11 L12 A13 Cr14 FInorg15 F16"        // &
                    !           " IInorg17 I18 PFInorg19 PF20 Ass21 FAEIng22 FAE23 JEM24 JE25 dE26"         // &
                    !           " GamLoss27 StruLoss28 JV29 JH30 MatLoss31 JS32 Gam33 JR34"   // &
                    !           " CO235 H2O36 O237 NH338 PO439"   // &
                    !           " m_A40 m_O41 m_F42 m_nat43 m_shr44 m_cra45 m_oys46 m_duck47 m_gull48  m_low49 "))

                    102 format( I4   , 1x, I2,    1x, I2,    1x, I2,    1x, I2,    1x, I2, 1x  , &  !6
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x                     , &  !10
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !15
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !20
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !25
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !30
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !35
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !40
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !45
                                E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x)                         !49

                    write(Cohort%CohortOutput%Unit, 102) int(Year), int(Month), int(Day)                            ,& !1,2,3
                                                         int(hour), int(minute), int(second)                        ,& !4,5,6
                                    Me%ExternalVar%Mass(Number,Index)    , Me%ExternalVar%Mass(M_E,Index)           ,& !7,8
                                    Me%ExternalVar%Mass(M_V,Index)       , Me%ExternalVar%Mass(M_H,Index)           ,& !9,10    
                                    Me%ExternalVar%Mass(M_R,Index)       , Me%ExternalVar%Mass(L,Index)             ,& !11,12    
                                    Me%ExternalVar%Mass(Age,Index)                                                  ,& !13
                                    Cohort%Processes%ClearanceRate       , Cohort%Processes%FilteredInorganic       ,& !14,15    
                                    Cohort%Processes%FilteredFood%C      , Cohort%Processes%IngestionInorganic      ,& !16,17
                                    Cohort%Processes%IngestionFood%C     , Cohort%Processes%PFContributionInorganic ,& !18,19
                                    Cohort%Processes%PFContributionFood%C, Cohort%Processes%Assimilation%C          ,& !20,21
                                    Cohort%Processes%FaecesContributionInorganic                                    ,& !22
                                    Cohort%Processes%FaecesContributionFood%C                                       ,& !23
                                    Cohort%Processes%SomaticMaintenance  , Cohort%Processes%Mobilization            ,& !24,25    
                                    Cohort%Processes%ReservesDynamics    , Cohort%Processes%GametesLoss             ,& !26,27    
                                    Cohort%Processes%StructureLoss       , Cohort%Processes%StructureDynamics       ,& !28,29    
                                    Cohort%Processes%MaturityDynamics    , Cohort%Processes%MaturityLoss            ,& !30,31    
                                    Cohort%Processes%Spawning            , Cohort%Processes%GametesToRelease        ,& !32,33    
                                    Cohort%Processes%ReproductionDynamics, Cohort%Processes%InorganicFluxes%CO2     ,& !34,35
                                    Cohort%Processes%InorganicFluxes%H2O , Cohort%Processes%InorganicFluxes%O2      ,& !36,37
                                    Cohort%Processes%InorganicFluxes%NH3 , Cohort%Processes%InorganicFluxes%PO4     ,& !38,39
                                    Cohort%Processes%DeathByAge          , Cohort%Processes%DeathByOxygen           ,& !40,41    
                                    Cohort%Processes%DeathByStarvation   , Cohort%Processes%DeathByNatural          ,& !42,43
                                    Cohort%Processes%PredationByShrimps  , Cohort%Processes%PredationByCrabs        ,& !44,45
                                    Cohort%Processes%PredationByOysterCatchers                                      ,& !46
                                    Cohort%Processes%PredationByEiderDucks                                          ,& !47
                                    Cohort%Processes%PredationByHerringGull                                         ,& !48
                                    Cohort%Processes%DeathByLowNumbers                                                 !49

                    Cohort => Cohort%Next
                end do d2
            end if
            
            if (Species%Population) then
 
!                OuputHeader =    "YY1 MM2 DD3 hh4 mm5 ss6 "                                                    // &
!                                " TN7 NCoh8 TBio9 Cr10 Fil11 Ing12 Ass13"                                      // &
!                                " CO14 H2O15 O16 NH317 PO418 LackOfFood19"                                     // &
!                                " m_A20 m_O21 m_F22 m_nat23 m_shr24 m_cra25 m_oys26 m_duck27 m_gull28 m_low29" // &
!                                " TMASSm_A30 TMASSm_O31 TMASSm_F32 TMASSm_nat33 TMASSm_shr34 TMASSm_cra35"     // &
!                                " TMASSm_oys36 TMASSm_duck37 TMASSm_gull38 TMASSm_low39"                       // &
!                                " GEOm_A40 GEOm_O41 GEOm_F42 GEOm_nat43 GEOm_shr44 GEOm_cra45 GEOm_oys46"      // &
!                                " GEOm_duck47 GEOm_gull48 GEOm_low49"                                          // &
!                                " TNField50 MaxLength51 SpawningEvents52"

                103 format( I4,    1x, I2,    1x, I2,    1x, I2,    1x, I2,    1x, I2, 1x  , &  !6
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x                     , &  !10
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !15
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !20
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !25
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !30
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !35
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !40
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !45
                            E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x, E12.4, 1x          , &  !50
                            E12.4, 1x, I4, 1x)                                               !51,52
                
                    write(Species%PopulationOutput%Unit, 103)   int(Year), int(Month), int(Day)                           ,& !1,2,3
                                                                int(hour), int(minute), int(second)                       ,& !4,5,6
                                                    Species%PopulationProcesses%TN  ,Species%PopulationProcesses%NCoh     ,& !7,8
                                                    Species%PopulationProcesses%TBio,Species%PopulationProcesses%Cr       ,& !9,10
                                                    Species%PopulationProcesses%Fil,Species%PopulationProcesses%Ing       ,& !11,12
                                                    Species%PopulationProcesses%Ass,Species%PopulationProcesses%CO2       ,& !13,14
                                                    Species%PopulationProcesses%H2O,Species%PopulationProcesses%O         ,& !15,16
                                                    Species%PopulationProcesses%NH3,Species%PopulationProcesses%PO4       ,& !17,18
                                                    Me%LackOfFood                                                         ,& !19
                                                    Species%PopulationProcesses%m_A,Species%PopulationProcesses%m_O       ,& !20,21
                                                    Species%PopulationProcesses%m_F,Species%PopulationProcesses%m_nat     ,& !22,23
                                                    Species%PopulationProcesses%m_shr,Species%PopulationProcesses%m_cra   ,& !24,25
                                                    Species%PopulationProcesses%m_oys,Species%PopulationProcesses%m_duck  ,& !26,27
                                                    Species%PopulationProcesses%m_gull,Species%PopulationProcesses%m_low  ,& !28,29    
                                                    Species%PopulationProcesses%SumAllMortalityInMass(1)                  ,& !30    
                                                    Species%PopulationProcesses%SumAllMortalityInMass(2)                  ,& !31    
                                                    Species%PopulationProcesses%SumAllMortalityInMass(3)                  ,& !32    
                                                    Species%PopulationProcesses%SumAllMortalityInMass(4)                  ,& !33
                                                    Species%PopulationProcesses%SumAllMortalityInMass(5)                  ,& !34    
                                                    Species%PopulationProcesses%SumAllMortalityInMass(6)                  ,& !35    
                                                    Species%PopulationProcesses%SumAllMortalityInMass(7)                  ,& !36
                                                    Species%PopulationProcesses%SumAllMortalityInMass(8)                  ,& !37
                                                    Species%PopulationProcesses%SumAllMortalityInMass(9)                  ,& !38
                                                    Species%PopulationProcesses%SumAllMortalityInMass(10)                 ,& !39
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(1)              ,& !40    
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(2)              ,& !41    
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(3)              ,& !42    
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(4)              ,& !43
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(5)              ,& !44    
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(6)              ,& !45    
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(7)              ,& !46
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(8)              ,& !47
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(9)              ,& !48
                                                    Species%PopulationProcesses%AverageMortalityInNumbers(10)             ,& !49
                                                    Species%PopulationProcesses%TNField                                   ,& !50
                                                    Species%PopulationProcesses%MaxLength                                 ,& !51
                                                    Species%PopulationProcesses%nSpawning                                    !52
                                                                        

                if (Species%BySizeOutput) then

                    call WriteSizeDistribution (Index, Species)

                end if
            
            end if !population
            
            Species => Species%Next
        end do d1

        if (Me%ComputeOptions%MassBalance .and. Me%OutputON) then

            call WriteMassBalance (Index)

        end if         

    end subroutine WriteOutput

    !--------------------------------------------------------------------------

    subroutine WriteMassBalance (Index)

    !Notes-----------------------------------------------------------------

    !Arguments-------------------------------------------------------------
    integer, intent(IN)           :: Index

    !Local-----------------------------------------------------------------
    type(T_Species),      pointer :: Species
    type(T_Cohort),       pointer :: Cohort
    real            :: RATIOHC, RATIOOC, RATIONC, RATIOPC 
    real            :: SumC, SumN, SumP  
    real            :: C_AtomicMass, H_AtomicMass, O_AtomicMass, N_AtomicMass, P_AtomicMass
    integer         :: M_V, M_E, M_R, Number    
    real            :: Year, Month, Day, hour, minute, second

    !Begin-----------------------------------------------------------------

    call ExtractDate(Me%CurrentTime, Year, Month, Day, hour, minute, second)

    !Assumed the samecomposition as the default values for bivalves if wq
    !The verification of teh mass is only possible if the ratios are the same for bivalve and phytoplankton
    ! or running with life because wq doe not follow POC and the ratio PON/POC is not known
    ! 0.3395653308501444 is an approximate value... 
    !Should be tested with life
    RATIOHC  = 0.15         
    RATIOOC  = 0.71         
    RATIONC  = 0.3 !0.3395653308501444         
    RATIOPC  = 0.07  

    !in g
    SumC = 0.0
    SumN = 0.0
    SumP = 0.0

    !folowing the constructed property list
    if (Me%ComputeOptions%PelagicModel .eq. LifeModel) then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%POC,Index) 

    else 

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%PON,Index) / RATIONC  

    end if

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%CarbonDioxide,Index)

    if(Me%ComputeOptions%Nitrogen)then   
    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%AM,Index)
    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%PON,Index)  
    end if

    if(Me%ComputeOptions%Phosphorus)then
    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%IP,Index)
    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%POP,Index)
    end if


    !Include All the cohorts from all the species      
    Species => Me%FirstSpecies
    do while(associated(Species))

    C_AtomicMass      = Species%AuxiliarParameters%C_AtomicMass        
    H_AtomicMass      = Species%AuxiliarParameters%H_AtomicMass        
    O_AtomicMass      = Species%AuxiliarParameters%O_AtomicMass        
    P_AtomicMass      = Species%AuxiliarParameters%P_AtomicMass        
    N_AtomicMass      = Species%AuxiliarParameters%N_AtomicMass        

    Cohort => Species%FirstCohort
    do while(associated(Cohort))

    M_V     = Cohort%StateIndex%M_V
    M_E     = Cohort%StateIndex%M_E
    M_R     = Cohort%StateIndex%M_R
    Number  = Cohort%StateIndex%Number

    SumC = SumC + Me%ExternalVar%Mass(M_V,Index) * C_AtomicMass * Me%ExternalVar%Mass(Number,Index)
    SumC = SumC + Me%ExternalVar%Mass(M_E,Index) * C_AtomicMass * Me%ExternalVar%Mass(Number,Index)
    SumC = SumC + Me%ExternalVar%Mass(M_R,Index) * C_AtomicMass * Me%ExternalVar%Mass(Number,Index)
    SumC = SumC + (Cohort%Processes%PredationByShrimps   + &
    Cohort%Processes%PredationByCrabs     + &      
    Cohort%Processes%PredationByOysterCatchers          + &
    Cohort%Processes%PredationByEiderDucks+ &     
    Cohort%Processes%PredationByHerringGull+&
    Cohort%Processes%DeathByLowNumbers) * Cohort%BivalveCondition%TotalmolC    * &
    Me%DTDay * C_AtomicMass 

    if(Me%ComputeOptions%Nitrogen)then   

    SumN = SumN + Me%ExternalVar%Mass(M_V,Index) * Species%SpeciesComposition%StructureComposition%nN  &
    * N_AtomicMass * Me%ExternalVar%Mass(Number,Index)

    SumN = SumN + Me%ExternalVar%Mass(M_E,Index) * Species%SpeciesComposition%ReservesComposition%nN   &
    * N_AtomicMass * Me%ExternalVar%Mass(Number,Index)

    SumN = SumN + Me%ExternalVar%Mass(M_R,Index) * Species%SpeciesComposition%ReservesComposition%nN   &
    * N_AtomicMass * Me%ExternalVar%Mass(Number,Index)

    SumN = SumN + (Cohort%Processes%PredationByShrimps   + &
    Cohort%Processes%PredationByCrabs     + &      
    Cohort%Processes%PredationByOysterCatchers          + &
    Cohort%Processes%PredationByEiderDucks+ &     
    Cohort%Processes%PredationByHerringGull + &
    Cohort%Processes%DeathByLowNumbers) * Cohort%BivalveCondition%TotalmolN    * &
    Me%DTDay * N_AtomicMass 

    end if

    if(Me%ComputeOptions%Phosphorus)then

    SumP = SumP + Me%ExternalVar%Mass(M_V,Index) * Species%SpeciesComposition%StructureComposition%nP  &
    * P_AtomicMass * Me%ExternalVar%Mass(Number,Index)

    SumP = SumP + Me%ExternalVar%Mass(M_E,Index) * Species%SpeciesComposition%ReservesComposition%nP   &
    * P_AtomicMass * Me%ExternalVar%Mass(Number,Index)

    SumP = SumP + Me%ExternalVar%Mass(M_R,Index) * Species%SpeciesComposition%ReservesComposition%nP   &
    * P_AtomicMass * Me%ExternalVar%Mass(Number,Index)

    SumP = SumP + (Cohort%Processes%PredationByShrimps   + &
    Cohort%Processes%PredationByCrabs     + &      
    Cohort%Processes%PredationByOysterCatchers          + &
    Cohort%Processes%PredationByEiderDucks+ &     
    Cohort%Processes%PredationByHerringGull+&
    Cohort%Processes%DeathByLowNumbers) * Cohort%BivalveCondition%TotalmolP    * &
    Me%DTDay * P_AtomicMass 

    end if

    Cohort => Cohort%Next
    end do

    SumC = SumC + Species%PopulationProcesses%nNewborns * (Species%IndividualParameters%MEb       * &
    Species%SpeciesComposition%ReservesComposition%nC    + &
    Species%IndividualParameters%MVb       * &
    Species%SpeciesComposition%StructureComposition%nC)

    SumN = SumN + Species%PopulationProcesses%nNewborns * (Species%IndividualParameters%MEb       * &
    Species%SpeciesComposition%ReservesComposition%nN    + &
    Species%IndividualParameters%MVb       * &
    Species%SpeciesComposition%StructureComposition%nN)

    SumP = SumP + Species%PopulationProcesses%nNewborns * (Species%IndividualParameters%MEb       * &
    Species%SpeciesComposition%ReservesComposition%nP    + &
    Species%IndividualParameters%MVb       * &
    Species%SpeciesComposition%StructureComposition%nP)


    Species => Species%Next
    end do

    if(Me%PropIndex%phyto .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%phyto,Index)

    if(Me%ComputeOptions%Nitrogen)then   
    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%phyto,Index) * RATIONC  
    end if

    if(Me%ComputeOptions%Phosphorus)then
    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%phyto,Index) * RATIOPC
    end if

    end if

    if(Me%PropIndex%zoo .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%zoo,Index)

    if(Me%ComputeOptions%Nitrogen)then   
    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%zoo,Index) * RATIONC 
    end if

    if(Me%ComputeOptions%Phosphorus)then
    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%zoo,Index) * RATIOPC 
    end if

    end if   

    if(Me%PropIndex%ciliate .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%ciliate,Index)

    if(Me%ComputeOptions%Nitrogen)then   
    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%ciliate,Index) * RATIONC 
    end if

    if(Me%ComputeOptions%Phosphorus)then
    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%ciliate,Index) * RATIOPC 
    end if

    end if      

    if(Me%PropIndex%bacteria .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%bacteria,Index)

    if(Me%ComputeOptions%Nitrogen)then   
    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%bacteria,Index) * RATIONC 
    end if

    if(Me%ComputeOptions%Phosphorus)then
    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%bacteria,Index) * RATIOPC 
    end if

    end if      

    if(Me%PropIndex%DiatomsC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%DiatomsC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%DiatomsN,Index) 

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%DiatomsP,Index) 

    end if      

    if(Me%PropIndex%diatoms .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%diatoms,Index)

    if(Me%ComputeOptions%Nitrogen)then   
    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%diatoms,Index) * RATIONC 
    end if

    if(Me%ComputeOptions%Phosphorus)then
    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%diatoms,Index) * RATIOPC 
    end if

    end if      

    if(Me%PropIndex%Mix_FlagellateC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%Mix_FlagellateC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%Mix_FlagellateN,Index)  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%Mix_FlagellateP,Index) 

    end if      


    if(Me%PropIndex%PicoalgaeC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%PicoalgaeC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%PicoalgaeN,Index)  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%PicoalgaeP,Index) 

    end if      

    if(Me%PropIndex%FlagellateC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%FlagellateC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%FlagellateN,Index) 

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%FlagellateP,Index)

    end if      

    if(Me%PropIndex%MicrozooplanktonC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%MicrozooplanktonC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%MicrozooplanktonN,Index) 

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%MicrozooplanktonP,Index) 

    end if      

    if(Me%PropIndex%Het_NanoflagellateC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%Het_NanoflagellateC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%Het_NanoflagellateN,Index)  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%Het_NanoflagellateP,Index)  

    end if      

    if(Me%PropIndex%MesozooplanktonC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%MesozooplanktonC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%MesozooplanktonN,Index) 

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%MesozooplanktonP,Index) 

    end if      


    if(Me%PropIndex%Het_BacteriaC .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%Het_BacteriaC,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%Het_BacteriaN,Index)  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%Het_BacteriaP,Index)  

    end if      

    if(Me%PropIndex%Shrimp .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%Shrimp,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%Shrimp,Index) * RATIONC  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%Shrimp,Index) * RATIOPC   

    end if

    if(Me%PropIndex%Crab .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%Crab,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%Crab,Index) * RATIONC  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%Crab,Index) * RATIOPC   

    end if

    if(Me%PropIndex%OysterCatcher .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%OysterCatcher,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%OysterCatcher,Index) * RATIONC  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%OysterCatcher,Index) * RATIOPC   

    end if

    if(Me%PropIndex%EiderDuck .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%EiderDuck,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%EiderDuck,Index) * RATIONC  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%EiderDuck,Index) * RATIOPC   

    end if 

    if(Me%PropIndex%HerringGull .ne. null_int)then

    SumC = SumC + Me%ExternalVar%Mass(Me%PropIndex%HerringGull,Index)

    SumN = SumN + Me%ExternalVar%Mass(Me%PropIndex%HerringGull,Index) * RATIONC  

    SumP = SumP + Me%ExternalVar%Mass(Me%PropIndex%HerringGull,Index) * RATIOPC   

    end if       

    101 format(I4,    1x, I2,    1x, I2,    1x, I2,    1x, I2,    1x, I2, 1x  ,&  !6 
    E16.8, 1x, E16.8, 1x, E16.8, 1x, E16.8, 1x)       !10

    102 format(I4,    1x, I2,    1x, I2,    1x, I2,    1x, I2,    1x, I2, 1x  ,&  !6 
    E16.8, 1x, E16.8, 1x, E16.8, 1x)    !9

    if (Me%ComputeOptions%PelagicModel .eq. LifeModel) then

    write(Me%MassOutput%Unit, 101)  int(Year), int(Month), int(Day)           ,& !1,2,3
    int(hour), int(minute), int(second)       ,& !4,5,6
    SumC, SumN, SumP, Me%MassLoss
    else

    write(Me%MassOutput%Unit, 102)  int(Year), int(Month), int(Day)           ,& !1,2,3
    int(hour), int(minute), int(second)       ,& !4,5,6
    SumN, SumP, Me%MassLoss
    end if

    end subroutine WriteMassBalance

    !--------------------------------------------------------------------------

    subroutine WriteSizeDistribution(Index, Species)

    !Notes-----------------------------------------------------------------

    !Arguments-------------------------------------------------------------
    integer, intent(IN)                 :: Index
    type(T_Species)          , pointer  :: Species

    !Local-----------------------------------------------------------------            
    type(T_Cohort)           , pointer  :: Cohort
    integer                             :: L, Number, iSizeClass    
    real                                :: lowsize, highsize 
    real                                :: Year, Month, Day, hour, minute, second


    !Begin-----------------------------------------------------------------

    call ExtractDate(Me%CurrentTime, Year, Month, Day, hour, minute, second)

    !Initialize
    Species%SizeFrequency = 0.0

    do iSizeClass = 1, Species%nSizeClasses

    lowsize  = Species%SizeClasses(iSizeClass)

    if (iSizeClass .lt. Species%nSizeClasses) then
    highsize = Species%SizeClasses(iSizeClass+1)
    else
    highsize = 1000.           
    end if

    Cohort => Species%FirstCohort
    do while(associated(Cohort))

    L       = Cohort%StateIndex%L
    Number  = Cohort%StateIndex%Number

    if ((Me%ExternalVar%Mass(L,Index) .ge. lowsize) .and. (Me%ExternalVar%Mass(L,Index) .lt. highsize)) then

    Species%SizeFrequency(iSizeClass) = Species%SizeFrequency(iSizeClass) + Me%ExternalVar%Mass(Number,Index)

    end if

    Cohort => Cohort%Next
    end do

    end do

    write(Species%SizeDistributionOutput%Unit, '(I4,1x,I2,1x, I2,1x, I2,1x, I2,1x, I2, 1x ,'//&
    Species%SizeClassesCharFormat//'E16.8, 1x)')  &
    int(Year), int(Month), int(Day) , & !1,2,3
    int(hour), int(minute), int(second), & !4,5,6
    Species%SizeFrequency





    !        101 format(I4,    1x, I2,    1x, I2,    1x, I2,    1x, I2,    1x, I2, 1x  ,&  !6 
    !     E16.8, 1x, E16.8, 1x, E16.8, 1x, E16.8, 1x       ,&  !10
    !     E16.8, 1x, E16.8, 1x, E16.8, 1x, E16.8, 1x, E16.8, 1x          ,&  !15
    !     E16.8, 1x) !16
    !   i = int(Year) 
    !        write(Species%SizeDistributionOutput%Unit, 101)  int(Year), int(Month), int(Day) , & !1,2,3
    ! int(hour), int(minute), int(second)           , & !4,5,6
    ! Species%SizeClasses(1),Species%SizeClasses(2) , & !7,8
    ! Species%SizeClasses(3),Species%SizeClasses(4) , & !9,10
    ! Species%SizeClasses(5),Species%SizeClasses(6) , & !11,12
    ! Species%SizeClasses(7),Species%SizeClasses(8) , & !13,14
    ! Species%SizeClasses(9),Species%SizeClasses(10)    !15,16



    end subroutine WriteSizeDistribution

    !--------------------------------------------------------------------------

    subroutine WriteTestingFile(Index)

        !Notes-----------------------------------------------------------------

        !Arguments-------------------------------------------------------------
        integer, intent(IN)                 :: Index

        !Local-----------------------------------------------------------------            
        integer                             :: STAT_CALL
        type(T_Cohort)           , pointer  :: Cohort
        type(T_Species)          , pointer  :: Species
        type(T_Predator)         , pointer  :: Predator
        integer                             :: L, Number    
        real                                :: TN,  Maxlength
        real                                :: m_A, m_O, m_F, m_nat
        real                                :: m_shr, m_cra, m_oys, m_duck, m_gull, m_low        
        integer                             :: TC,Evaluation 
        !real                                :: Year, Month, Day, hour, minute, second
        character(len=500)                  :: ParameterValueStr
        character(len=500)                  :: CompleteLineStr
        
        !Begin-----------------------------------------------------------------
        
        Species => Me%FirstSpecies
        do while(associated(Species))

            call UnitsManager(Species%TestingParametersOutput%Unit, OPEN_FILE, STAT = STAT_CALL)
            if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine WriteTestingFile - ModuleBivalve - ERR01'
            
            open(Unit = Species%TestingParametersOutput%Unit, File = trim(Species%Testing_File)   , &
                                                              Status = 'UNKNOWN', Access = 'APPEND' )
            
            TN = 0.0
            TC = 0.0
            
            if (Species%nCohorts .eq. 0) then
            

                TN = 0.0
                TC = 0.0
                
                Maxlength = Species%PopulationProcesses%LastLength
                
                m_A    = Species%PopulationProcesses%LastCauseofDeath(1)
                m_O    = Species%PopulationProcesses%LastCauseofDeath(2)
                m_F    = Species%PopulationProcesses%LastCauseofDeath(3)
                m_nat  = Species%PopulationProcesses%LastCauseofDeath(4)
                m_shr  = Species%PopulationProcesses%LastCauseofDeath(5)
                m_cra  = Species%PopulationProcesses%LastCauseofDeath(6)
                m_oys  = Species%PopulationProcesses%LastCauseofDeath(7)
                m_duck = Species%PopulationProcesses%LastCauseofDeath(8)
                m_gull = Species%PopulationProcesses%LastCauseofDeath(9)
                m_low  = Species%PopulationProcesses%LastCauseofDeath(10)
                
            else
            
                Cohort => Species%FirstCohort
                do while(associated(Cohort))

                    L       = Cohort%StateIndex%L
                    Number  = Cohort%StateIndex%Number

                    TN = TN + Me%ExternalVar%Mass(Number,Index)
                    TC = TC + 1
                    
                    Maxlength = max(Maxlength,Me%ExternalVar%Mass(L,Index))
                     
                    Cohort => Cohort%Next
                end do
                
                if (Maxlength .lt. 1.0e-15) then           
                    Maxlength = 0.0
                end if  
                
                m_A    = 0.0
                m_O    = 0.0
                m_F    = 0.0
                m_nat  = 0.0
                m_shr  = 0.0
                m_cra  = 0.0
                m_oys  = 0.0
                m_duck = 0.0
                m_gull = 0.0
                m_low  = 0.0
                
            end if
            
            CompleteLineStr = trim(Species%ID%Name)//' '
            
            Predator => Species%FirstPredator
            do while(associated(Predator))
            
                write(ParameterValueStr, ('(F7.4)')) Predator%Diet
                
                CompleteLineStr = trim(CompleteLineStr)//' '//trim(ParameterValueStr)
            
                Predator => Predator%Next
            end do
                
            100 format(E12.5, 1x, E12.5, 1x, E12.5, 1x, E12.5, 1x, E12.5, 1x, I5, 1x     , &
                       E12.5, 1x, E12.5, 1x, E12.5, 1x, E12.5, 1x, E12.5, 1x             , & !5
                       E12.5, 1x, E12.5, 1x, E12.5, 1x, E12.5, 1x, E12.5, 1x, I4, 1x)     !6
            
            write(ParameterValueStr, 100) Me%DT                                                   , &   
                                          Species%IndividualParameters%m_spat                     , &
                                          Species%IndividualParameters%m_natural                  , &
                                          TN                                                      , &
                                          Maxlength                                               , &
                                          TC                                                      , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(1)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(2)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(3)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(4)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(5)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(6)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(7)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(8)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(9)                    , &
                                          Species%PopulationProcesses%AverageMortalityInNumbers(10)                   , &
                                          Species%PopulationProcesses%nSpawning                    
                                         
            CompleteLineStr = trim(CompleteLineStr)//' '//trim(ParameterValueStr)

            !Compute Evaluation
            if (TN .gt. 0.0) then
                Evaluation = 1 !Alive
            else
                if ( (m_shr+m_cra+m_oys+m_duck+m_gull) .gt. 0.0 ) then
                    Evaluation = -1 !Died from some predation
                else
                    if (m_F .gt. 0.0 ) then
                        Evaluation = 0  !Died from starvation
                    else
                        if (m_nat .gt. 0.0 ) then
                            Evaluation = -2  !Died from natural causes
                        else
                            if (m_A .gt. 0.0 ) then
                                Evaluation = -3  !Died from age
                            else
                                if (m_low .gt. 0.0 ) then
                                    Evaluation = -4  !Died from low numbers
                                else
                                    Evaluation = -5  !Died from oxygen depletion
                                end if
                            end if
                        end if
                    end if
                end if
            end if
    
            write(ParameterValueStr, ('(I5)')) Evaluation

            CompleteLineStr = trim(CompleteLineStr)//' '//trim(ParameterValueStr)

            101 format(A500)             
            
            write(Species%TestingParametersOutput%Unit, 101) CompleteLineStr
            
!            !write the Rfile with name of the files, MakeRplotsPopulation
!            
!            call UnitsManager(Species%MakeRplotsPopulation%Unit, OPEN_FILE, STAT = STAT_CALL)
!            if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine WriteTestingFile - ModuleBivalve - ERR02'
!                        
!            open(Unit = Species%MakeRplotsPopulation%Unit, File = trim(Species%MakeRplotsPopulation%FileName)   , &
!                                                       Status = 'UNKNOWN', Access = 'APPEND' )
!                                                                   
!            CompleteLineStr = 'CompareField_TotalNumbers( "Data/v1/'//trim(Species%PopulationOutput%FileName)// &
!                              '", FieldTotalNumbersFileName,"'// trim(Species%PopulationOutput%FileName)//        &
!                              '", timeforplots, ClassesNames)'
!            
!            write(Species%MakeRplotsPopulation%Unit, 101) CompleteLineStr
!            
!            !write the Rfile with name of the files, MakeRplotsSizeDistribution
!                                                  
!            call UnitsManager(Species%MakeRplotsSizeDistribution%Unit, OPEN_FILE, STAT = STAT_CALL)
!            if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine WriteTestingFile - ModuleBivalve - ERR02'
!                        
!            open(Unit = Species%MakeRplotsSizeDistribution%Unit, File = trim(Species%MakeRplotsSizeDistribution%FileName) , &
!                                                                 Status = 'UNKNOWN', Access = 'APPEND' )
!                                                                  
!            CompleteLineStr = 'CompareField_SizeDistribution( "Data/v1/'//trim(Species%SizeDistributionOutput%FileName)// &
!                              '", FieldSizeDistributionFileName,"'// trim(Species%SizeDistributionOutput%FileName)//           &
!                              '", timeforplots, ClassesNames)'
!            write(Species%MakeRplotsSizeDistribution%Unit, 101) CompleteLineStr            
                  
            Species => Species%Next
        end do

    end subroutine WriteTestingFile

    !--------------------------------------------------------------------------

    subroutine UpdateCohortState
        !Arguments-------------------------------------------------------------

        !Local-----------------------------------------------------------------
        type(T_Cohort)           , pointer          :: Cohort
        type(T_Species)          , pointer          :: Species
        !----------------------------------------------------------------------
  
        Species  => Me%FirstSpecies
d1:     do while (associated(Species))

            Cohort  => Species%FirstCohort
d2:         do while (associated(Cohort))

                Cohort%GlobalDeath = Cohort%GlobalDeath * Cohort%Dead

                Cohort  => Cohort%Next  
            end do  d2        

            Species  => Species%Next  
        enddo  d1

    end subroutine UpdateCohortState

    !--------------------------------------------------------------------------

    subroutine RestoreUnits (Index)
        !Arguments-------------------------------------------------------------
        integer                                     :: Index
        
        !Local-----------------------------------------------------------------
        type(T_Species)         , pointer           :: Species
        type(T_Cohort)          , pointer           :: Cohort
        integer                                     :: Number
        integer                                     :: Shrimp, Crab, OysterCatcher
        integer                                     :: EiderDuck, HerringGull

        !Begin-----------------------------------------------------------------
        
        Shrimp        = Me%PropIndex%Shrimp
        Crab          = Me%PropIndex%Crab
        OysterCatcher = Me%PropIndex%OysterCatcher
        EiderDuck     = Me%PropIndex%EiderDuck
        HerringGull   = Me%PropIndex%HerringGull

        Species => Me%FirstSpecies
        do while(associated(Species))
            
            Cohort => Species%FirstCohort
            do while(associated(Cohort))
            
                Number = Cohort%StateIndex%Number 
                         
                !Reconvert the mussels organisms density from /m3 to /m2
                if (Me%DensityUnits .eq. 0)  then !if units for mussel density are in /m2
                
                    Me%ExternalVar%Mass(Number,Index) = Me%ExternalVar%Mass(Number,Index)       * &
                                                        Me%ExternalVar%CellVolume(Index)        * &
                                                        1./Me%ExternalVar%CellArea(Index)
                end if
                
                Cohort => Cohort%Next

            end do
                                    
            Species => Species%Next

        end do
        
        !Convert the predators organisms density to /m3
        if(Shrimp .ne. null_int)then

            Me%ExternalVar%Mass(Shrimp,Index) = Me%ExternalVar%Mass(Shrimp,Index)               * &
                                                Me%ExternalVar%CellVolume(Index)                * &
                                                1./Me%ExternalVar%CellArea(Index)
        end if

        if(Crab .ne. null_int)then

            Me%ExternalVar%Mass(Crab,Index) = Me%ExternalVar%Mass(Crab,Index)                   * &
                                              Me%ExternalVar%CellVolume(Index)                  * &
                                              1./Me%ExternalVar%CellArea(Index)
        end if
        
        if(Me%PropIndex%Crab .ne. null_int)then

            Me%ExternalVar%Mass(OysterCatcher,Index) = Me%ExternalVar%Mass(OysterCatcher,Index) * &
                                                       Me%ExternalVar%CellVolume(Index)         * &
                                                       1./Me%ExternalVar%CellArea(Index)
        end if

        if(Me%PropIndex%Crab .ne. null_int)then

            Me%ExternalVar%Mass(EiderDuck,Index) = Me%ExternalVar%Mass(EiderDuck,Index)         * &
                                                   Me%ExternalVar%CellVolume(Index)             * &
                                                   1./Me%ExternalVar%CellArea(Index) 
        end if

    end subroutine RestoreUnits

    !--------------------------------------------------------------------------

    subroutine UpdateListDeadAndNewBornIDs
        !Arguments-------------------------------------------------------------

        !Local-----------------------------------------------------------------
        integer                                     :: DynamicCohortPropertyID
        type(T_Cohort)           , pointer          :: Cohort
        type(T_Species)          , pointer          :: Species
        !----------------------------------------------------------------------
  
        Species  => Me%FirstSpecies
d1:     do while (associated(Species))

            if (Species%NewbornCohort) then
            
                !Add the PopulationProcesses%nNewborns of this species to the ListNewbornsIDs   
                Me%nLastNewbornsID = Me%nLastNewbornsID + 1
                Me%ListNewbornsIDs(Me%nLastNewbornsID) = Species%ID%IDNumber
                
            end if
                
            Cohort  => Species%FirstCohort
d2:         do while (associated(Cohort))

                if (Cohort%GlobalDeath .eq. 1) then
                 
                    Me%nLastDeadID = Me%nLastDeadID + 1
                    DynamicCohortPropertyID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" structure")
                    Me%ListDeadIDs(Me%nLastDeadID) = DynamicCohortPropertyID

                    Me%nLastDeadID = Me%nLastDeadID + 1
                    DynamicCohortPropertyID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" reserves")
                    Me%ListDeadIDs(Me%nLastDeadID) = DynamicCohortPropertyID

                    Me%nLastDeadID = Me%nLastDeadID + 1
                    DynamicCohortPropertyID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" maturity")
                    Me%ListDeadIDs(Me%nLastDeadID) = DynamicCohortPropertyID

                    Me%nLastDeadID = Me%nLastDeadID + 1
                    DynamicCohortPropertyID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" reproduction")
                    Me%ListDeadIDs(Me%nLastDeadID) = DynamicCohortPropertyID

                    Me%nLastDeadID = Me%nLastDeadID + 1
                    DynamicCohortPropertyID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" length")
                    Me%ListDeadIDs(Me%nLastDeadID) = DynamicCohortPropertyID

                    Me%nLastDeadID = Me%nLastDeadID + 1
                    DynamicCohortPropertyID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" age")
                    Me%ListDeadIDs(Me%nLastDeadID) = DynamicCohortPropertyID

                    Me%nLastDeadID = Me%nLastDeadID + 1
                    DynamicCohortPropertyID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" number")
                    Me%ListDeadIDs(Me%nLastDeadID) = DynamicCohortPropertyID
                                
                end if 

                Cohort  => Cohort%Next  

            end do  d2        

            Species  => Species%Next  
        enddo  d1
        
    end subroutine UpdateListDeadAndNewBornIDs

    !--------------------------------------------------------------------------

    subroutine UpdateBivalvePropertyList
        
        !Arguments------------------------------------------------------------------

        !Local----------------------------------------------------------------------

        !---------------------------------------------------------------------------

        call RemoveDeadIDsFromSpecies

        call AddNewbornsToSpecies

        call PropertyIndexNumber

        call ConstructPropertyList

    end subroutine UpdateBivalvePropertyList

    !--------------------------------------------------------------------------

    subroutine RemoveDeadIDsFromSpecies 

        !Local-----------------------------------------------------------------
        type (T_Species)           , pointer      :: Species
        type (T_Cohort)            , pointer      :: Cohort
        type (T_Cohort)            , pointer      :: CohortToContinue
        integer                                   :: iDeadIDs = 0,DynamicCohortID 
        !----------------------------------------------------------------------

        Species  => Me%FirstSpecies
d1:     do while (associated(Species))

            Cohort  => Species%FirstCohort
d2:         do while (associated(Cohort))

                iDeadIDs = 1
                DynamicCohortID = GetDynamicPropertyIDNumber(trim(adjustl(Cohort%ID%Name))//" structure")

                do iDeadIDs = 1, Me%nLastDeadID

                    if (Me%ListDeadIDs(iDeadIDs) .eq. DynamicCohortID) then

                        CohortToContinue => Cohort%Next

                        call RemoveCohortFromList (Species, Cohort)

                        exit
                                            
                    endif

                end do

                if(associated(CohortToContinue)) then 
                    Cohort => CohortToContinue
                    nullify(CohortToContinue)
                else
                    if (associated(Cohort)) Cohort  => Cohort%Next
                end if

            end do  d2        

            Species  => Species%Next  
        enddo  d1

    end subroutine RemoveDeadIDsFromSpecies

    !--------------------------------------------------------------------------       

    subroutine RemoveCohortFromList (ObjSpecies, ObjCohort)

        !Arguments-----------------------------------------------------------------
        type (T_Species), pointer     :: ObjSpecies
        type (T_Cohort), pointer      :: ObjCohort         

        !Local-----------------------------------------------------------------
        type (T_Cohort), pointer      :: Cohort           => null()
        type (T_Cohort), pointer      :: PreviousCohort   => null()
        integer                       :: STAT_CALL
        !----------------------------------------------------------------------

        nullify(Cohort, PreviousCohort)

        Cohort  => ObjSpecies%FirstCohort
        do while (associated(Cohort))

            if (Cohort%ID%ID .eq. ObjCohort%ID%ID) then  !this is the cohort to be removed            

                if(associated(PreviousCohort))then
                    PreviousCohort%Next      => Cohort%Next
                else
                    ObjSpecies%FirstCohort   => Cohort%Next
                end if

                ObjSpecies%nCohorts  = ObjSpecies%nCohorts - 1
                
                if (ObjSpecies%CohortOutput) then

                    call UnitsManager(Cohort%CohortOutput%Unit, CLOSE_FILE, STAT = STAT_CALL)
                    if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine CloseFiles - ModuleBivalve - ERR01'

                end if

                if(associated(Cohort%FeedingOn)) deallocate (Cohort%FeedingOn)

                deallocate    (Cohort)
                nullify       (Cohort)

                cycle

            else

                PreviousCohort => Cohort
                Cohort  => Cohort%Next

            endif

        enddo 

        nullify(ObjCohort)

    end subroutine RemoveCohortFromList

    !--------------------------------------------------------------------------

    subroutine AddNewbornsToSpecies 

        !Local-----------------------------------------------------------------
        type (T_Species), pointer                   :: Species
        
        Me%nLastNewbornsID = 0

        Species  => Me%FirstSpecies
d1:     do while (associated(Species))

            if (Species%NewbornCohort) then
            
                !Add the PopulationProcesses%nNewborns of this species to the ListNewbornsIDs   
                Me%nLastNewbornsID = Me%nLastNewbornsID + 1
                Me%ListNewbornsIDs(Me%nLastNewbornsID) = Species%ID%IDNumber

                call ConstructCohort (Species)
            
            end if
            
            Species  => Species%Next  
        enddo  d1

    end subroutine AddNewbornsToSpecies  

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    !DESTRUCTOR DESTRUCTOR DESTRUCTOR DESTRUCTOR DESTRUCTOR DESTRUCTOR DESTRUCTOR DEST

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    subroutine KillBivalve(ObjBivalveID, STAT)

        !Arguments--------------------------------------------------------------------
        integer :: ObjBivalveID
        integer, optional, intent(OUT)      :: STAT

        !External---------------------------------------------------------------------
        integer :: ready_

        !Local------------------------------------------------------------------------
        integer :: STAT_, nUsers           
        type (T_Species)  , pointer     :: Species
        type (T_Cohort)   , pointer     :: Cohort
        !-----------------------------------------------------------------------------

        STAT_ = UNKNOWN_

        call Ready(ObjBivalveID, ready_)
        
        if (Me%Testing_Parameters) then
        
            call WriteTestingFile (Me%Array%ILB)

        end if

cd1 :   if (ready_ .NE. OFF_ERR_) then

                nUsers = DeassociateInstance(mBivalve_,  Me%InstanceID)

            if (nUsers == 0) then

                !deallocate everything inside the cohorts and species
                Species => Me%FirstSpecies
                do while(associated(Species))

                    Cohort => Species%FirstCohort
                    do while(associated(Cohort))

                        !soffs
                        if(associated(Cohort%FeedingOn)) deallocate (Cohort%FeedingOn)

                        !deallocate(Cohort%FeedingOn)

                    Cohort  => Cohort%Next  
                    enddo
                    
                    deallocate (Species%FirstCohort)
                    nullify    (Species%FirstCohort)
                    
                    deallocate (Species%FirstParticles)
                    nullify    (Species%FirstParticles)

                    deallocate (Species%FirstPredator)
                    nullify    (Species%FirstPredator)

                    deallocate (Species%SizeClasses)
                    deallocate (Species%SizeFrequency)

                    deallocate (Species%PopulationProcesses%LastCauseofDeath)
                    deallocate (Species%PopulationProcesses%SumLogAllMortalityInNumbers)
                    deallocate (Species%PopulationProcesses%SumAllMortalityInMass)
                    deallocate (Species%PopulationProcesses%AverageMortalityInNumbers)
                   
                Species  => Species%Next  
                enddo
                
                deallocate (Me%FirstSpecies)

                if(associated(Me%ListDeadIDs )) deallocate (Me%ListDeadIDs)
                if(associated(Me%MatrixNewborns)) deallocate (Me%MatrixNewborns)

                call CloseFiles

                if (Me%ObjTime /= 0) then
                    nUsers = DeassociateInstance(mTIME_, Me%ObjTime)
                    if (nUsers == 0) stop 'KillBivalve - ModuleBivalve - ERR00'
                endif    

                !Deallocates Instance
                call DeallocateInstance ()

                ObjBivalveID = 0
                STAT_      = SUCCESS_

            end if
        else 
            STAT_ = ready_
        end if cd1

        if (present(STAT)) STAT = STAT_

    !---------------------------------------------------------------------------

    end subroutine KillBivalve


    !-------------------------------------------------------------------------------

    subroutine CloseFiles

        !Local----------------------------------------------------------------------
        integer                                   :: STAT_CALL
        type (T_Species)         , pointer        :: Species

        !Begin----------------------------------------------------------------------

        Species => Me%FirstSpecies
        do while(associated(Species))

            if (Species%Population) then
                call UnitsManager(Species%PopulationOutput%Unit, CLOSE_FILE, STAT = STAT_CALL)
                if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine CloseFiles - ModuleBivalve - ERR01'
            end if

            if (Species%BySizeOutput) then
                call UnitsManager(Species%SizeDistributionOutput%Unit, CLOSE_FILE, STAT = STAT_CALL)
                if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine CloseFiles - ModuleBivalve - ERR02'
            end if
            
            if (Me%Testing_Parameters) then
                call UnitsManager(Species%TestingParametersOutput%Unit, CLOSE_FILE, STAT = STAT_CALL)
                if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine CloseFiles - ModuleBivalve - ERR03'

!                call UnitsManager(Species%MakeRplotsPopulation%Unit, CLOSE_FILE, STAT = STAT_CALL)
!                if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine CloseFiles - ModuleBivalve - ERR04'
!
!                call UnitsManager(Species%MakeRplotsSizeDistribution%Unit, CLOSE_FILE, STAT = STAT_CALL)
!                if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine CloseFiles - ModuleBivalve - ERR05'

            end if

            Species => Species%Next
        enddo

        if (Me%ComputeOptions%MassBalance) then
            call UnitsManager(Me%MassOutput%Unit, CLOSE_FILE, STAT = STAT_CALL)
            if (STAT_CALL .NE. SUCCESS_) stop 'Subroutine CloseFiles - ModuleBivalve - ERR03'
        end if

    end subroutine CloseFiles

    !-------------------------------------------------------------------------------

    subroutine DeallocateInstance ()

    !Arguments------------------------------------------------------------------

    !Local----------------------------------------------------------------------
    type (T_Bivalve), pointer          :: AuxObjBivalve
    type (T_Bivalve), pointer          :: PreviousObjBivalve

    !Updates pointers
    if (Me%InstanceID == FirstObjBivalve%InstanceID) then
    FirstObjBivalve => FirstObjBivalve%Next
    else
    PreviousObjBivalve => FirstObjBivalve
    AuxObjBivalve      => FirstObjBivalve%Next
    do while (AuxObjBivalve%InstanceID /= Me%InstanceID)
    PreviousObjBivalve => AuxObjBivalve
    AuxObjBivalve      => AuxObjBivalve%Next
    enddo

    !Now update linked list
    PreviousObjBivalve%Next => AuxObjBivalve%Next

    endif

    !Deallocates instance
    deallocate (Me)
    nullify    (Me) 


    end subroutine DeallocateInstance

    !-------------------------------------------------------------------------------
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    !MANAGEMENT MANAGEMENT MANAGEMENT MANAGEMENT MANAGEMENT MANAGEMENT MANAGEME

    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    !-------------------------------------------------------------------------------

    subroutine Ready (ObjBivalve_ID, ready_) 

    !Arguments------------------------------------------------------------------
    integer         :: ObjBivalve_ID
    integer         :: ready_

    !---------------------------------------------------------------------------

    nullify (Me)

    cd1:    if (ObjBivalve_ID > 0) then
    call LocateObjBivalve (ObjBivalve_ID)
    ready_ = VerifyReadLock (mBivalve_, Me%InstanceID)
    else
    ready_ = OFF_ERR_
    end if cd1

    !---------------------------------------------------------------------------

    end subroutine Ready

    !-------------------------------------------------------------------------------

    subroutine LocateObjBivalve (ObjBivalveID)

    !Arguments------------------------------------------------------------------
    integer         :: ObjBivalveID

    !Local----------------------------------------------------------------------

    Me => FirstObjBivalve
    do while (associated (Me))
    if (Me%InstanceID == ObjBivalveID) exit
    Me => Me%Next
    enddo

    if (.not. associated(Me)) stop 'ModuleBivalve - LocateObjBivalve - ERR01'

    end subroutine LocateObjBivalve

    !-------------------------------------------------------------------------------

    end module ModuleBivalve
