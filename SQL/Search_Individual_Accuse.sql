select * FROM ACCUSED_INDIVIDUAL ai
          JOIN INCIDENT i on i.PRISM_File_ID = ai.PRISM_File_ID
          join PRISM_FILE PF on PF.PRISM_File_ID = ai.PRISM_File_ID
          JOIN ACCUSED_INVOLVED aci on aci.Incident_ID = i.Incident_ID
          JOIN INDIVIDUAL_ACCUSED_INVOLVED iai
            ON ai.Accused_Individual_ID = iai.Accused_Individual_ID
          AND iai.Accused_Involved_ID = aci.Accused_Involved_ID
          --AND iai.Charged_Under_Individual_ID = @old_individual_id
            WHERE pf.PRISM_File_Number = '200948446P101'
          AND aci.Involvement_Type_Code = 'ACC'
          AND aci.Master_Accused_Involved_ID IS NULL