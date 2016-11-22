type ModeType: string // "WALK","BICYCLE","CAR","TRAM","SUBWAY","RAIL",
                      // "BUS","FERRY","CABLE_CAR","GONDOLA","FUNICULAR",
                      // "TRANSIT","TRAIN","TRAINISH","BUSISH","LEG_SWITCH","TAXI"
type FareType: void {
  .co2: double
  .points: double | void
}

type ItineraryType: void {
  .signature?: string
  .startTime: TimeType
  .endTime: TimeType
  .mode?: ModeType
  .waitingTime?: int
  .fare?: FareType
  .legs: void {
    .leg*: LegType
  }
}

type UUIDType: string
type TimeType: long
type LatitudeType: double
type LongitudeType: double
type LocationType: void {
  .lat: LatitudeType
  .lon: LongitudeType
}
type ShortLocationType: void {
  ._: void { 
    .longitude: LongitudeType
    .latitude: LatitudeType
  }
}

type DistanceType: double
type kmDistanceType: double
type PhoneType: string
type EmailType: string
type AddressType: string
type PlaceType: void {
  .lat: LatitudeType // Extend Jolie to handle Subtyping?
  .lon: LongitudeType // 
  .name: string
  .address: AddressType
}
type PriceType: 
  void { .amount: double .currency: string } // "EUR", "POINT"
  | undefined // has additionalProperties: true

type LegType: LegCoreType | WaitingLegType | TranferLegType

type LegCoreType: undefined | // has additionalProperties: true
void {
 .signature?: string
 .from: PlaceType
 .to: PlaceType
 .startTime: TimeType
 .endTime: TimeType
 .mode: ModeType
 .departureDelay?: int
 .arrivalDelay?: int
 .distance?: double
 .state?: string // "START", "PLANNED", "PAID", "ACTIVATED", "CANCELLED", "FINISHED"
  .route?: string
  .routeShortName?: string
  .routeLongName?: string
  .agencyId?: string
  .legGeometry?: LegGeometryType
}

type WaitingLegType: undefined | // has additionalProperties: true
void {
  .startTime: TimeType
  .endTime: TimeType
  .mode: string // the value is always "WAIT"          
}

type TranferLegType: undefined | // has additionalProperties: true
void {
  .startTime: TimeType
  .endTime: TimeType
  .mode: ModeType // "TRANSFER"
}

type LegGeometryType: void { .points: string } 
                | undefined // WARNING, has additionalProperties: true
                            // LegGeometryType can include 
                            // unknown subnodes with unknown type

type CustomerType: void {
  .title: string // "mr", "ms", "mrs", "company"
  .firstName: string
  .lastName: string
  .phone: string
  .email: string
}


type BookingCreateRequest: void {
  .leg: LegType
  .meta: void {
    .description: string
  }
  .customer: CustomerType
}

type BookingStateType: string // START, PENDING, RESERVED, PAID, 
                              // ACTIVATED, CANCELLED, EXPIRED, 
                              // RECONCILING, RESOLVED, REJECTED,

type BookingCoreType: undefined | // has additionalProperties: true
void { 
  .id: UUIDType
  .tspId: string
  .state: BookingStateType
  .meta?: MetaType
  .terms: TermsType
  .token?: TokenType
  .customer: CustomerType
}

type BookingType: undefined | 
void {
  .id: UUIDType
  .tspId: string
  .state: BookingStateType
  .meta?: MetaType
  .terms: TermsType
  .token?: TokenType
  .customer: CustomerType
  .leg: LegType
}

type BookingCreateResponse: void {
  .leg: LegType
  .meta: MetaType
  .terms: TermsType
  .token: TokenType
  .customer: CustomerType
  .tspId: string
}

type MetaType: undefined // has additionalProperties: true 
// below it should be a oneOf relation, meaning only one can be present
| void {
  .MODE_WALK?: void
  .MODE_BICYCLE?: void
  .MODE_CAR?: void {
    .name: string
    .description: void { .type: string }
    .image: void { .type: string .format: string /* URL */ }
    .car?: void { .passengers: void { .type: int } }
  }
  .MODE_TRAM?: void
  .MODE_SUBWAY?: void
  .MODE_RAIL?: void
  .MODE_BUS?: void
  .MODE_FERRY?: void
  .MODE_CABLE_CAR?: void
  .MODE_GONDOLA?: void
  .MODE_FUNICULAR?: void
  .MODE_TRANSIT?: void
  .MODE_TRAIN?: void
  .MODE_TRAINISH?: void
  .MODE_BUSISH?: void
  .MODE_LEG_SWITCH?: void
  .MODE_TAXI?: void
}

type TermsType: void {
  .price: PriceType
}

type TokenType: void {
  .validityDuration: void {
    .from: TimeType
    .to: TimeType
  }
  .meta: void
}