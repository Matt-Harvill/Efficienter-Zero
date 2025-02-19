# distutils: language=c++
from libcpp.vector cimport vector


cdef extern from "cminimax.cpp":
    pass


cdef extern from "cminimax.h" namespace "tools":
    cdef cppclass CMinMaxStats:
        CMinMaxStats() except +
        float maximum, minimum, value_delta_max

        void set_delta(float value_delta_max)
        void update(float value)
        void clear()
        float normalize(float value)

    cdef cppclass CMinMaxStatsList:
        CMinMaxStatsList() except +
        CMinMaxStatsList(int num, int searches) except +
        int num, searches
        vector[vector[CMinMaxStats]] stats_lsts

        void set_delta(float value_delta_max)

cdef extern from "cnode.cpp":
    pass


cdef extern from "cnode.h" namespace "tree":
    cdef cppclass CNode:
        CNode() except +
        CNode(float prior, int action_num, vector[CNode]* ptr_node_pool) except +
        int visit_count, to_play, action_num, hidden_state_index_x, hidden_state_index_y, hidden_state_index_z, best_action
        float value_prefixs, prior, value_sum
        vector[int] children_index;
        vector[CNode]* ptr_node_pool;

        void expand(int to_play, int hidden_state_index_x, int hidden_state_index_y, int hidden_state_index_z, float value_prefixs, vector[float] policy_logits)
        void add_exploration_noise(float exploration_fraction, vector[float] noises)
        float get_mean_q(int isRoot, float parent_q, float discount)

        int expanded()
        float value()
        vector[int] get_trajectory()
        vector[int] get_children_distribution()
        vector[float] get_children_value()
        CNode* get_child(int action)

    cdef cppclass CRoots:
        CRoots() except +
        CRoots(int root_num, int action_num, int pool_size) except +
        int root_num, action_num, pool_size
        vector[CNode] roots
        vector[vector[CNode]] node_pools

        void prepare(float root_exploration_fraction, const vector[vector[float]] &noises, const vector[float] &value_prefixs, const vector[vector[float]] &policies)
        void prepare_no_noise(const vector[float] &value_prefixs, const vector[vector[float]] &policies)
        void clear()
        vector[vector[int]] get_trajectories()
        vector[vector[int]] get_distributions()
        vector[vector[float]] get_children_values()
        vector[float] get_values()

    cdef cppclass CSearchResults:
        CSearchResults() except +
        CSearchResults(int num, int searches) except +

        int num, searches
        float PUCT_average_score, num_PUCT_scores
        vector[int] num_searched
        vector[vector[int]] hidden_state_index_x_lst, hidden_state_index_y_lst, hidden_state_index_z_lst, last_actions, search_lens
        vector[vector[CNode*]] nodes
        vector[vector[vector[CNode*]]] search_paths

    cdef void cback_propagate(vector[CNode*] &search_path, CMinMaxStats &min_max_stats, int to_play, float value, float discount)
    void cbatch_back_propagate(int hidden_state_index_x, float discount, vector[vector[float]] value_prefixs, vector[vector[float]] values, vector[vector[vector[float]]] policies,
                               CMinMaxStatsList *min_max_stats_lst, CSearchResults &results, vector[vector[int]] is_reset_lst)
    float cbatch_traverse(CRoots *roots, int pb_c_base, float pb_c_init, float discount, CMinMaxStatsList *min_max_stats_lst, CSearchResults &results)
