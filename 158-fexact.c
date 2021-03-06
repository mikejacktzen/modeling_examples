#include <apop.h>

int main(){
    int readin_status = apop_text_to_db("amash_vote_analysis.csv", .tabname="amash");
    Apop_stopif( readin_status== -1, exit(1), 0, "Trouble reading in the data. "
                     "Have you downloaded it to this directory?");

    apop_query("create table pv_xtab as "
               " select party, vote, count(*) as ct "
               " from amash "
               " group by party, vote ");

    apop_data *xtab = apop_db_to_crosstab("pv_xtab", "party", "vote", "ct");
    apop_data_show(xtab);
    apop_data_show(apop_test_fisher_exact(xtab));
}
