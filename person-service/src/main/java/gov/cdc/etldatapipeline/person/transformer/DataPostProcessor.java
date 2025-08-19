package gov.cdc.etldatapipeline.person.transformer;

import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientReporting;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.*;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderElasticSearch;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderReporting;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.ObjectUtils;

import java.util.*;
import java.util.function.Function;
import java.util.function.Predicate;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.deserializePayload;
import static java.util.Objects.requireNonNull;
import static java.util.stream.Collectors.groupingBy;
import static java.util.stream.Collectors.toList;

@Slf4j
@NoArgsConstructor
public class DataPostProcessor {
    /**
     * 1. For patient name_use_cd = {L, AL}
     * 2. For providers  name_use_cd = {L}
     * - For every name array, get the json node with the max patient_uid and person_seq_num
     *
     * @param name Array of Json Objects with the history of the name changes
     * @param pf   Transformed Patient/Provider Object
     * @param <T>  Object extending PersonExtendedProps
     */
    public <T extends PersonExtendedProps> void processPersonName(String name, T pf) {
        if (!ObjectUtils.isEmpty(name)) {
            NameUseCd[] nameUseCds = NameUseCd.values();
            if (pf.getClass() == ProviderReporting.class || pf.getClass() == ProviderElasticSearch.class) {
                nameUseCds = List.of(NameUseCd.LEGAL).toArray(NameUseCd[]::new);
            }
            Arrays.stream(nameUseCds).forEach(cd -> {
                TreeMap<Long, List<Name>> nameMap = Arrays.stream(requireNonNull(deserializePayload(name, Name[].class)))
                        .filter(pName -> !ObjectUtils.isEmpty(pName.getPersonUid()))
                        // Filter by Name types: L-Legal, AL-Alias
                        .filter(pName -> ObjectUtils.isEmpty(pName.getNmUseCd()) || pName.getNmUseCd().equals(cd.getVal()))
                        // Sort by the getPersonUid and collect all the entries with max PersonUid to a List
                        .collect(groupingBy(Name::getPersonUid, TreeMap::new, toList()));
                // Get the last entry which is the max PersonUid
                if (!nameMap.isEmpty()) {
                    nameMap.lastEntry()
                            .getValue()
                            .stream()
                            .filter(pName -> !ObjectUtils.isEmpty(pName.getPersonNmSeq()))
                            // Get the entry with the max Person Name Sequence
                            .max(Comparator.comparing(n -> {
                                try {
                                    return Integer.parseInt(n.getPersonNmSeq());
                                } catch (NumberFormatException e) {
                                    log.warn("Invalid person name sequence number: {}", n.getPersonNmSeq());
                                    return 0; 
                                }
                            }))
                            .ifPresent(n -> n.updatePerson(pf, cd.getVal()));
                }
            });
        }
    }

    public <T extends PersonExtendedProps> void processPersonAddress(String address, T pf) {
        if (!ObjectUtils.isEmpty(address)) {

            // deserialize once, guarantee non-null, pre-filter out payloads without postal locator
            List<Address> addrData = Arrays.stream(requireNonNull(deserializePayload(address, Address[].class)))
                    .filter(pa -> !ObjectUtils.isEmpty(pa.getPostalLocatorUid())).toList();

            if(pf.getClass() == PatientReporting.class || pf.getClass() == PatientElasticSearch.class) {
                addrData.stream()
                        .filter(pa -> "H".equalsIgnoreCase(pa.getUseCd()))
                        .max(Comparator.comparing(Address::getPostalLocatorUid))
                        .ifPresent(n -> n.updatePerson(pf));
                addrData.stream()
                        .filter(pa -> "BIR".equalsIgnoreCase(pa.getUseCd()))
                        .max(Comparator.comparing(Address::getPostalLocatorUid))
                        .ifPresent(n -> n.updatePerson(pf));
            } else if (pf.getClass() == ProviderReporting.class || pf.getClass() == ProviderElasticSearch.class) {
                addrData.stream()
                        .filter(pa -> "WP".equalsIgnoreCase(pa.getUseCd()))
                        .max(Comparator.comparing(Address::getPostalLocatorUid))
                        .ifPresent(n -> n.updatePerson(pf));
            }
        }
    }

    public <T extends PersonExtendedProps> void processPersonRace(String race, T pf) {
        if (!ObjectUtils.isEmpty(race)) {
            Arrays.stream(requireNonNull(deserializePayload(race, Race[].class)))
                    .filter(pRace -> !ObjectUtils.isEmpty(pRace.getPersonUid()))
                    .max(Comparator.comparing(Race::getPersonUid))
                    .ifPresent(n -> n.updatePerson(pf));
        }
    }

    public <T extends PersonExtendedProps> void processPersonTelephone(String telephone, T pf) {
        if (ObjectUtils.isEmpty(telephone)) {
            return;
        }

        // Deserialize once
        Phone[] allData = requireNonNull(deserializePayload(telephone, Phone[].class));

        // --- Special work phone logic for ProviderReporting / ProviderElasticSearch ---
        if (pf instanceof ProviderReporting || pf instanceof ProviderElasticSearch) {
            Phone workPhone = Arrays.stream(allData)
                    .filter(p -> "WP".equalsIgnoreCase(p.getUseCd()) && "O".equalsIgnoreCase(p.getCd()))
                    .max(Comparator.comparing(Phone::getTeleLocatorUid))
                    .orElse(null);

            if (workPhone == null) {
                workPhone = Arrays.stream(allData)
                        .filter(p -> "WP".equalsIgnoreCase(p.getUseCd()))
                        .max(Comparator.comparing(Phone::getTeleLocatorUid))
                        .orElse(null);
            }

            if (workPhone != null) {
                workPhone.updatePerson(pf); // delegate update
            }
        } else {
            Arrays.stream(allData)
                    .filter(p -> "WP".equalsIgnoreCase(p.getUseCd()))
                    .max(Comparator.comparing(Phone::getTeleLocatorUid))
                    .ifPresent(p -> p.updatePerson(pf)); // delegate update
        }

        Function<Predicate<? super Phone>, T> personPhoneFn =
            p -> Arrays.stream(allData)
                    .filter(p)
                    .max(Comparator.comparing(Phone::getTeleLocatorUid))
                    .map(n -> n.updatePerson(pf))
                    .orElse(null);

        // --- Home phone ---
        personPhoneFn.apply(p -> "H".equalsIgnoreCase(p.getUseCd()));

        // --- Cell phone ---
        personPhoneFn.apply(p -> "CP".equalsIgnoreCase(p.getCd()));

    }

    public <T extends PersonExtendedProps> void processPersonEntityData(String entityData, T pf) {
        if (!ObjectUtils.isEmpty(entityData)) {

            // deserialize once, guarantee non-null
            EntityData[] allData = requireNonNull(deserializePayload(entityData, EntityData[].class));

            Function<Predicate<? super EntityData>, T> entityDataTypeCdFn =
                    p -> Arrays.stream(allData)
                            .filter(e -> !ObjectUtils.isEmpty(e.getEntityIdSeq()))
                            .filter(p)
                            .max(Comparator.comparing(EntityData::getEntityIdSeq))
                            .map(n -> n.updatePerson(pf))
                            .orElse(null);
            entityDataTypeCdFn.apply(e -> "SSA".equalsIgnoreCase(e.getAssigningAuthorityCd()));
            entityDataTypeCdFn.apply(e -> "PN".equalsIgnoreCase(e.getTypeCd()));
            entityDataTypeCdFn.apply(e -> "QEC".equalsIgnoreCase(e.getTypeCd()));
            entityDataTypeCdFn.apply(e -> "PRN".equalsIgnoreCase(e.getTypeCd()));
            entityDataTypeCdFn.apply(e -> "NPI".equalsIgnoreCase(e.getTypeCd()));
        }
    }

    public <T extends PersonExtendedProps> void processPersonEmail(String email, T pf) {
        if (!ObjectUtils.isEmpty(email)) {
            Arrays.stream(requireNonNull(deserializePayload(email, Email[].class)))
                    .filter(pEmail -> !ObjectUtils.isEmpty(pEmail.getTeleLocatorUid()))
                    .max(Comparator.comparing(Email::getTeleLocatorUid))
                    .ifPresent(n -> n.updatePerson(pf));
        }
    }
}
